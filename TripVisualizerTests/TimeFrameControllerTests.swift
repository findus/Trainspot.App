//
//  TimeFrameControllerTests.swift
//  LocationManagerTestTests
//
//  Created by Philipp Hentschel on 13.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

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
        
        self.delegate = MockDelegate()
        
        self.dataProvider = MockTrainDataTimeFrameProvider()
        controller = TrainLocationTripByTimeFrameController(dateGenerator: timeProvider.generateDate)
        controller.setDataProvider(withProvider: TripProvider(dataProvider))
        controller.delegate = delegate
        controller.setCurrentLocation(location: CLLocation(latitude: 1, longitude: 1))
        
    }
    
    private func reloadTrips() {
        guard let trip = dataProvider.getAllTrips().first else {
            XCTFail("Trip could not be loaded")
            return
        }
        
        self.initialTrip = trip
    }
   
    //MARK:-- Trip Staring
 
    func testCorrectTripStateBeginning() {
        self.dataProvider.update()
        self.reloadTrips()
        
        guard let journeyStart = self.initialTrip?.departure else {
            XCTFail("Could not get departure date")
            return
        }
        
        self.timeProvider.date = journeyStart
        
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        controller.pause()
        guard let (_, data, _) = delegate.updatedArray.first else {
            XCTFail("No trip data available")
            return
        }
        XCTAssertEqual(data.state.get(), "Lehrte")
    }
    
    func testCorrectTripStateBeforeBeginning() {
        self.dataProvider.update()
        self.reloadTrips()
        
        guard let journeyStart = self.initialTrip?.departure else {
            XCTFail("Could not get departure date")
            return
        }
        
        self.timeProvider.date = journeyStart.addingTimeInterval(-1)
        
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        controller.pause()
        guard let (_, data, _) = delegate.updatedArray.first else {
            XCTFail("No trip data available")
            return
        }
        XCTAssertEqual(data.state.get(), "Wait for Start")
    }
    
    //MARK:-- Trip Ending
    
    func testCorrectTripStateEnding() {
        self.dataProvider.update()
        self.reloadTrips()
        
        guard let journeyEnd = (self.initialTrip?.locationArray.last as? StopOver)?.arrival else {
            XCTFail("Could not get arrival stopover")
            return
        }
        
        self.timeProvider.date = journeyEnd
        
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        controller.pause()
        guard let (_, data, _) = delegate.updatedArray.first else {
            XCTFail("No trip data available")
            return
        }
        XCTAssertEqual(data.state.get(), "Ended")
    }
    
    func testCorrectTripStateBeforeEnding() {
        self.dataProvider.update()
        self.reloadTrips()
        
        guard let journeyEnd = (self.initialTrip?.locationArray.last as? StopOver)?.arrival else {
            XCTFail("Could not get arrival stopover")
            return
        }
        
        self.timeProvider.date = journeyEnd.addingTimeInterval(-1)
        
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        controller.pause()
        guard let (_, data, _) = delegate.updatedArray.first else {
            XCTFail("No trip data available")
            return
        }
        XCTAssertEqual(data.state.get(), "Braunschweig Hbf")
    }
    
    func testCorrectTripStateAfterEnding() {
        self.dataProvider.update()
        self.reloadTrips()
        
        guard let journeyEnd = (self.initialTrip?.locationArray.last as? StopOver)?.arrival else {
            XCTFail("Could not get arrival stopover")
            return
        }
        
        self.timeProvider.date = journeyEnd.addingTimeInterval(1)
        
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        controller.pause()
        guard let (_, data, _) = delegate.updatedArray.first else {
            XCTFail("No trip data available")
            return
        }
        XCTAssertEqual(data.state.get(), "Ended")
    }
    
    //MARK:-- Stopping
    
    func testCorrectTripStateBeforeStop() {
        self.dataProvider.update()
        self.reloadTrips()
        
        //2020-06-12T16:34:0
        var components = DateComponents()
        components.second = 0
        components.hour = 16
        components.minute = 34
        components.day = 12
        components.month = 6
        components.year = 2020
        guard let date = Calendar.current.date(from: components) else {
            XCTFail("Could not parse date")
            return
        }

        self.timeProvider.date = date.addingTimeInterval(-1)
        
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        controller.pause()
        guard let (_, data, _) = delegate.updatedArray.first else {
            XCTFail("No trip data available")
            return
        }
        
        XCTAssertEqual(data.state.get(), "Hämelerwald")
    }
    
    func testCorrectTripStateAtStop() {
        self.dataProvider.update()
        self.reloadTrips()
        
        //2020-06-12T16:34:0
        var components = DateComponents()
        components.second = 0
        components.hour = 16
        components.minute = 34
        components.day = 12
        components.month = 6
        components.year = 2020
        guard let date = Calendar.current.date(from: components) else {
            XCTFail("Could not parse date")
            return
        }

        self.timeProvider.date = date
        
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        controller.pause()
        guard let (_, data, _) = delegate.updatedArray.first else {
            XCTFail("No trip data available")
            return
        }
        
        XCTAssertTrue(data.state.get().contains("Stopped for"))
    }
    
    func testCorrectTripStateAtStopEnding() {
        self.dataProvider.update()
        self.reloadTrips()
        
        //2020-06-12T16:34:0
        var components = DateComponents()
        components.second = 0
        components.hour = 16
        components.minute = 34
        components.day = 12
        components.month = 6
        components.year = 2020
        guard let date = Calendar.current.date(from: components) else {
            XCTFail("Could not parse date")
            return
        }

        self.timeProvider.date = date.addingTimeInterval(59)
        
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        controller.pause()
        guard let (_, data, _) = delegate.updatedArray.first else {
            XCTFail("No trip data available")
            return
        }
        
        XCTAssertTrue(data.state.get().contains("Stopped for"))
    }
    
    func testCorrectTripStateAtStopEnded() {
        self.dataProvider.update()
        self.reloadTrips()
        
        //2020-06-12T16:34:0
        var components = DateComponents()
        components.second = 0
        components.hour = 16
        components.minute = 34
        components.day = 12
        components.month = 6
        components.year = 2020
        guard let date = Calendar.current.date(from: components) else {
            XCTFail("Could not parse date")
            return
        }

        self.timeProvider.date = date.addingTimeInterval(60)
        
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        controller.pause()
        guard let (_, data, _) = delegate.updatedArray.first else {
            XCTFail("No trip data available")
            return
        }
        
        XCTAssertEqual(data.state.get(),"Vöhrum")
    }
    
    //MARK: -- Trip Start Distance
    
    func testTripArrivalTimeOnStart() {
        
        self.controller.setCurrentLocation(location: CLLocation(latitude: 52.243616, longitude: 10.514395))
        self.dataProvider.setTrip(withName: "wfb_trip_bielefeld")
        self.dataProvider.update()
        self.reloadTrips()
                
        guard let journeyStart = self.initialTrip?.departure else {
            XCTFail("Could not get departure date")
            return
        }
        
        self.timeProvider.date = journeyStart.addingTimeInterval(60)
        
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        controller.pause()
        guard let (_, data, _) = delegate.updatedArray.first else {
            XCTFail("No trip data available")
            return
        }

        print(data.arrival)
        XCTAssertTrue(data.arrival ?? -1.0 > 0.0)
        XCTAssertEqual(data.state.get(),"Vechelde")
    }

}
