//
//  MockTrainDataJourneyProvider.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import SwiftyJSON

class MockTrainDataJourneyProvider: TrainDataProviderProtocol {

    typealias TripData = JourneyTrip
    
    func getAllTrips() -> Array<JourneyTrip> {
        guard let json = loadJSON(), let journeyTrips = HafasParser.loadJourneyTrip(fromJSON: json) else {
            return []
        }
        return journeyTrips
    }
    
    func update() {
        
    }
    
    private func loadJSON() -> JSON? {
        guard
            let filePath = Bundle(for: type(of: self)).path(forResource: "trip_test", ofType: ""),
            let wf_trip_data = NSData(contentsOfFile: filePath) else {
                return nil
        }
        
        return try! JSON(data: wf_trip_data as Data)
        
    }
}

