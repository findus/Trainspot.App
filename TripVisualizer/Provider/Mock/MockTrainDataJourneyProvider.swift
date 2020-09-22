//
//  MockTrainDataJourneyProvider.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import SwiftyJSON

public class MockTrainDataJourneyProvider: TrainDataProviderProtocol {
   
    public var delegate: TrainDataProviderDelegate? = nil
    
    public typealias TripData = JourneyTrip
    
    public init(){}
    
    public func getAllTrips() -> Set<JourneyTrip> {
//        guard let json = loadJSON(), let journeyTrips = HafasParser.loadJourneyTrip(fromJSON: json) else {
//            return []
//        }
        fatalError("Unimplemented")
    }
    
    public func update() {
        fatalError("Unimplemented")
    }
    
    public func updateExistingTrips(_ trips: Array<JourneyTrip>) {
        fatalError("Unimplemented")
    }
    
    public func setDeleate(delegate: TrainDataProviderDelegate) {

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

