//
//  TimeFrameControllerTests.swift
//  LocationManagerTestTests
//
//  Created by Philipp Hentschel on 13.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

import XCTest
@testable import TripVisualizer

class MockDelegate: NSObject, TrainLocationDelegate {
    var id = "MockDelegate"
    
    var updatedArray: Array<(trip: Trip, data: TripData, duration: Double)> = []
    var updated = XCTestExpectation(description: "Trainposition Updated called")
    func trainPositionUpdated(forTrip trip: Trip, withData data: TripData, withDuration duration: Double) {
        updatedArray.append((trip,data, duration))
        updated.fulfill()
    }
    var removed = XCTestExpectation(description: "Remove Called")
    func removeTripFromMap(forTrip trip: Trip) {
        removed.fulfill()
    }
    
    var draw = XCTestExpectation(description: "draw called")
    func drawPolyLine(forTrip: Trip) {
        draw.fulfill()
    }
    
    
}

class TimeFrameControllerTests: XCTestCase {

    var controller = TrainLocationTripByTimeFrameController()
    var dataProvider = MockTrainDataTimeFrameProvider()
    var initialTrip: TimeFrameTrip?
    var delegate = MockDelegate()
    var timeProvider = TimeTraveler()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        let delegate = MockDelegate()
        
        self.dataProvider = MockTrainDataTimeFrameProvider()
        controller = TrainLocationTripByTimeFrameController(dateGenerator: timeProvider.generateDate)
        controller.setDataProvider(withProvider: TripProvider(dataProvider))
        controller.delegate = delegate
        self.dataProvider.update()
        
        guard let trip = dataProvider.getAllTrips().first else {
            XCTFail("Trip could not be loaded")
            return
        }
        
        self.initialTrip = trip
    }
    
    func testMinPosition() {
        guard let journeyStart = self.initialTrip?.departure else {
            XCTFail("Could not get departure date")
            return
        }
        
        self.timeProvider.date = journeyStart
        
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        controller.pause()
        XCTAssertEqual(delegate.updatedArray.first?.data.state.get(), "Lehrte")
    }

}
