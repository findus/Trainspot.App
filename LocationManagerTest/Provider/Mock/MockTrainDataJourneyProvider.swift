//
//  MockTrainDataJourneyProvider.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreLocation

class MockTrainDataJourneyProvider: TrainDataProviderProtocol {
    
    private func loadTrips() -> Array<Trip>? {
        guard
            let filePath = Bundle(for: type(of: self)).path(forResource: "trip_test", ofType: ""),
            let wf_trip_data = NSData(contentsOfFile: filePath) else {
                return nil
        }
        
        let json = try! JSON(data: wf_trip_data as Data)
        
        let trips = json.arrayValue
            .filter({ $0["line"]["id"].stringValue != "bus-sev" })
            .filter({ $0["line"]["name"].stringValue != "Bus SEV" })
            .map { (json) -> Trip in
                let coords = json["polyline"]["features"].arrayValue.map { MapEntity(name: "line", location: CLLocation(latitude: $0["geometry"]["coordinates"][1].doubleValue, longitude: $0["geometry"]["coordinates"][0].doubleValue ))  }
                let framecount = json["frames"].arrayValue.count
                print("Frames  ", framecount)
                let polylinecount = json["polyline"]["features"].arrayValue.count
                print("Polyline", polylinecount)
                
                let name = json["line"]["name"]
                
                return Trip(withFetchTime: Date(), andName: name.stringValue, andLines: coords)
        }
        
        return trips

    }
    
    func getAllTrips() -> Array<Trip> {
        return loadTrips() ?? Array.init()
    }
    
    private func getJourneys(fromJSON json: JSON) -> Array<Journey> {
        json.arrayValue
            .filter({ ["nationalExpress", "national", "regionalExp", "regional"].contains(where: $0["line"]["product"].stringValue.contains)  })
            .map { Journey(from_id: $0["stop"]["id"].stringValue, from: $0["stop"]["name"].stringValue, to: $0["direction"].stringValue, tripID: $0["tripId"].stringValue) }
    }
}

