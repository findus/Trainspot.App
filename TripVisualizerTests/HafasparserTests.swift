//
//  HafasparserTests.swift
//  TripVisualizerTests
//
//  Created by Philipp Hentschel on 23.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import XCTest

@testable import TripVisualizer

class HafasparserTests: XCTestCase {
    
    let dateFormatter = DateFormatter()
    
    var tripProvider: MockTrainDataTimeFrameProvider? = nil
    
    override func setUp() {
        self.tripProvider = MockTrainDataTimeFrameProvider(withFile: "wfb_trip_45_min_delay_to_bs")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    }
    
    
    private func loadTrip(fromFile file: String) -> TimeFrameTrip? {
        let provider = MockTrainDataTimeFrameProvider(withFile: file)
        guard let hafasTrip = provider.loadTrip() else {
            return nil
        }
        
        guard let timeFrameTripWithDelay =  HafasParser.loadTimeFrameTrip(fromHafasTrips: Set([hafasTrip])).first else {
            XCTFail("This should not fail, the parser must parse this trip correctly")
            return nil
        }
        
        return timeFrameTripWithDelay
    }
    
    
    /**
     This trip has a delay of 25 minutes between Vechelde and Braunschweig.
     In order to get accurate animation data, the delay must get passed to all prior stops that have a delay value of nil, because hafas drops old
     delay data as soon as the train departs
     **/
    func testDelay() {
       
        guard let tripWithDelay = self.loadTrip(fromFile: "wfb_trip_25_min_delay_to_bs") else {
            XCTFail("Could not load trip")
            return
        }
       
        //Same Trip without Delay
        guard let tripWithoutDelay = self.loadTrip(fromFile: "wfb_trip") else {
            XCTFail("Could not load trip")
            return
        }
            
        // Drop final destination
        tripWithDelay.locationArray.dropLast().filter({$0 is StopOver}).forEach { (feature) in
            let stopover = feature as! StopOver
            XCTAssertEqual(stopover.arrivalDelay, 60*25 , "(\(stopover.name)) Every stop should now have an arrivaldelay of 45 minutes")
        }
        
        // Every trip departure before the first "real" occured delay should be moved 25 minutes into the future
        zip(tripWithoutDelay.locationArray, tripWithDelay.locationArray).forEach { (normal,with_delay) in
            XCTAssertEqual(with_delay.departure, normal.departure?.addingTimeInterval(60*25))
        }
            
    }
}
