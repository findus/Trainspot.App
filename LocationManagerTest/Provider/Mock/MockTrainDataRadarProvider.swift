//
//  MockTrainDataProvider.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreLocation

class MockTrainDataProvider : TrainDataProviderProtocol {
    
    private var trips : Array<RadarTrip>? = nil
    
    init() {
        self.trips = self.loadTrips()
    }
    
    private func loadTrips() -> Array<RadarTrip>? {
        guard
            let filePath = Bundle(for: type(of: self)).path(forResource: "data2", ofType: ""),
            let data = NSData(contentsOfFile: filePath) else {
                return nil
        }
        
        let json = try! JSON(data: data as Data)
        
        
        
        let trips = json.arrayValue
            .filter({ $0["line"]["id"].stringValue != "bus-sev" })
            .filter({ $0["line"]["name"].stringValue != "Bus SEV" })
            .map { (json) -> RadarTrip in
                let coords = json["polyline"]["features"].arrayValue.map { MapEntity(name: "line", location: CLLocation(latitude: $0["geometry"]["coordinates"][1].doubleValue, longitude: $0["geometry"]["coordinates"][0].doubleValue ))  }
                let framecount = json["frames"].arrayValue.count
                print("Frames  ", framecount)
                let polylinecount = json["polyline"]["features"].arrayValue.count
                print("Polyline", polylinecount)
                
                let name = json["line"]["name"]
                
                return RadarTrip(withFetchTime: Date(), andName: name.stringValue, andLines: coords, isType: "radar")
        }
        
        return trips

    }

    func getAllTrips() -> Array<Trip> {
        return trips ?? []
    }

}
