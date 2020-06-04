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
    
    private var journeys : Array<Journey>? = nil
    
    init() {
        self.journeys = self.loadJourneys()
    }
    
    private func loadJourneys() -> Array<Journey>? {
        guard
            let filePath = Bundle(for: type(of: self)).path(forResource: "data2", ofType: ""),
            let data = NSData(contentsOfFile: filePath) else {
                return nil
        }
        
        let json = try! JSON(data: data as Data)
        
        
        
        let journeys = json.arrayValue
            .filter({ $0["line"]["id"].stringValue != "bus-sev" })
            .filter({ $0["line"]["name"].stringValue != "Bus SEV" })
            .map { (json) -> Journey in
                let coords = json["polyline"]["features"].arrayValue.map { MapEntity(name: "line", location: CLLocation(latitude: $0["geometry"]["coordinates"][1].doubleValue, longitude: $0["geometry"]["coordinates"][0].doubleValue ))  }
                let framecount = json["frames"].arrayValue.count
                print("Frames  ", framecount)
                let polylinecount = json["polyline"]["features"].arrayValue.count
                print("Polyline", polylinecount)
                
                let name = json["line"]["name"]
                
                return Journey(withFetchTime: Date(), andName: name.stringValue, andLines: coords)
        }
        
        return journeys

    }

    
    func getAllJourneys() -> Array<Journey> {
        return journeys ?? []
    }
    
    
}
