//
//  MockTrainDataProvider.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftyJSON

class MockTrainDataRadarProvider : TrainDataProviderProtocol {
   
    var delegate: TrainDataProviderDelegate? = nil

    private var trips : Set<RadarTrip>? = nil
    
    init() {
        self.trips = self.loadTrips()
    }
    
    func update() {
        fatalError("Unimplemented")
    }
    
    func updateExistingTrips(_ trips: Array<RadarTrip>) {
          fatalError("Unimplemented")
    }
    
    func setDeleate(delegate: TrainDataProviderDelegate) {

    }
    
    private func loadTrips() -> Set<RadarTrip>? {
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
                //TODO TripId
                let coords = json["polyline"]["features"].arrayValue.map { MapEntity(name: "line", tripId: "e", location: CLLocation(latitude: $0["geometry"]["coordinates"][1].doubleValue, longitude: $0["geometry"]["coordinates"][0].doubleValue ))  }
                let framecount = json["frames"].arrayValue.count
                print("Frames  ", framecount)
                let polylinecount = json["polyline"]["features"].arrayValue.count
                print("Polyline", polylinecount)
                
                let name = json["line"]["name"]
                
                //TODO parse id
                return RadarTrip(withDeparture: Date(), andName: name.stringValue, andLines: coords, isType: "radar", andId: "e", withDestination: "-")
        }
        
        return Set(trips)

    }

    func getAllTrips() -> Set<RadarTrip> {
        return trips ?? Set.init()
    }

}
