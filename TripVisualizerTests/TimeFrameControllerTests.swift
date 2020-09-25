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
   
    func onUpdateEnded(withResult result: Result) {
        
    }
    
    func onUpdateStarted() {
        
    }
    
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
    var dataProvider = MockTrainDataTimeFrameProvider(withFile: "wfb_trip")
    var initialTrip: TimeFrameTrip?
    var delegate = MockDelegate()
    var timeProvider = TimeTraveler()
    
    override func setUp()  {
        self.delegate = MockDelegate()
        
        self.dataProvider = MockTrainDataTimeFrameProvider(withFile: "wfb_trip")
        self.controller = TrainLocationTripByTimeFrameController(dateGenerator: timeProvider.generateDate)
        self.controller.setDataProvider(withProvider: TripProvider(dataProvider))
        self.controller.delegate = delegate
    }
    
    override func tearDown() {
        self.controller.pause()
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
        XCTAssertEqual(data.state.get(), "Abfahrt in 1s")
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
        XCTAssertEqual(data.state.get(), "Ende")
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
        XCTAssertEqual(data.state.get(), "Ende")
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
    
    //MARK: -- Arrival Time
    
    /*
     |__T__*______|
     BS    ME     V
     */
    func testTripArrivalTime() {
        
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
        XCTAssertTrue(data.arrival > 0.0)
        XCTAssertEqual(data.state.get(),"Vechelde")
    }
    
    /*
     Check if the arrival date is zero if you are right next to the train when it is departing
     */
    func testTripArrivalTimeAtStart() {
        
        self.dataProvider.setTrip(withName: "wfb_trip_bielefeld")
        self.dataProvider.update()
        self.reloadTrips()
        
        guard let initialTrip = self.initialTrip else {
            XCTFail("Failed to get trip")
            return
        }
        
        self.controller.setCurrentLocation(location: initialTrip.locationArray.first!.coords)
                
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

        print(data.arrival)
        XCTAssertEqual(data.arrival, 0)
        XCTAssertEqual(data.state.get(),"Vechelde")
    }
    
    /*
        Check if the arrival date is zero if you are right next to the train when it is arriving
        */
       func testTripArrivalTimeAtEnd() {
           
        self.dataProvider.setTrip(withName: "wfb_trip_bielefeld")
        self.dataProvider.update()
        self.reloadTrips()
        
        guard let initialTrip = self.initialTrip else {
            XCTFail("Failed to get trip")
            return
        }
        
        self.controller.setCurrentLocation(location: initialTrip.locationArray.last!.coords)
        
        guard let journeyEnd = (self.initialTrip?.locationArray.last as? StopOver)?.arrival else {
            XCTFail("Could not get arrival date")
            return
        }
        
        self.timeProvider.date = journeyEnd.addingTimeInterval(0)
        
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        controller.pause()
        guard let (_, data, _) = delegate.updatedArray.first else {
            XCTFail("No trip data available")
            return
        }
        
        print(data.arrival)
        XCTAssertEqual(data.arrival, 0)
        XCTAssertEqual(data.state.get(),"Ende")
       }
    
    //MARK: - Grace Period Starting
    
    /**
     Up to a user-configurable, certain point, trains that are about to depart should also be displayed in their respective starting locations
     */
    func testGracePeriodBeforeStart() {
        
     self.dataProvider.setTrip(withName: "wfb_trip_bielefeld")
     self.dataProvider.update()
     self.reloadTrips()
     
     guard let initialTrip = self.initialTrip else {
         XCTFail("Failed to get trip")
         return
     }
     
     self.controller.setCurrentLocation(location: initialTrip.locationArray.first!.coords)
             
     guard let journeyStart = self.initialTrip?.departure else {
         XCTFail("Could not get departure date")
         return
     }
     
        self.timeProvider.date = journeyStart.addingTimeInterval(-100)
     
     controller.start()
     wait(for: [self.delegate.updated], timeout: 10)
     controller.pause()
     guard let (_, data, _) = delegate.updatedArray.first else {
         XCTFail("No trip data available")
         return
     }

     print(data.arrival)
     XCTAssertEqual(data.state.get(),"Abfahrt in 100s")
    }
    
    func testGracePeriodBeforeStart1s() {
        
     self.dataProvider.setTrip(withName: "wfb_trip_bielefeld")
     self.dataProvider.update()
     self.reloadTrips()
     
     guard let initialTrip = self.initialTrip else {
         XCTFail("Failed to get trip")
         return
     }
     
     self.controller.setCurrentLocation(location: initialTrip.locationArray.first!.coords)
             
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

     print(data.arrival)
     XCTAssertEqual(data.state.get(),"Abfahrt in 1s")
    }
    
    func testGracePeriodBeforeStartTooLate() {
        
     self.dataProvider.setTrip(withName: "wfb_trip_bielefeld")
     self.dataProvider.update()
     self.reloadTrips()
        self.controller.GRACE_PERIOD = 1
     
     guard let initialTrip = self.initialTrip else {
         XCTFail("Failed to get trip")
         return
     }
     
     self.controller.setCurrentLocation(location: initialTrip.locationArray.first!.coords)
             
     guard let journeyStart = self.initialTrip?.departure else {
         XCTFail("Could not get departure date")
         return
     }
     
        self.timeProvider.date = journeyStart.addingTimeInterval(-2)
     
     controller.start()
     wait(for: [self.delegate.updated], timeout: 10)
     controller.pause()
     guard let (_, data, _) = delegate.updatedArray.first else {
         XCTFail("No trip data available")
         return
     }

     print(data.arrival)
        XCTAssertEqual(data.state.get(), "Departs to late")
    }
    
    
    func testArrivalDateBeforeDeparture() {
        
        self.dataProvider.setTrip(withName: "wfb_trip_bielefeld")
        self.dataProvider.update()
        self.reloadTrips()
        self.controller.GRACE_PERIOD = 900
        
        guard let initialTrip = self.initialTrip else {
            XCTFail("Failed to get trip")
            return
        }
        
        self.controller.setCurrentLocation(location: initialTrip.locationArray.first!.coords)
        
        guard let journeyStart = self.initialTrip?.departure else {
            XCTFail("Could not get departure date")
            return
        }
        
        self.timeProvider.date = journeyStart.addingTimeInterval(-10)
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        controller.pause()
        self.timeProvider.date = journeyStart.addingTimeInterval(-9)
        self.delegate.updated = XCTestExpectation()
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        controller.pause()
        guard let (_, data, _) = delegate.updatedArray.first else {
            XCTFail("No trip data available")
            return
        }
        
        guard let (_, data2, _) = delegate.updatedArray.last else {
            XCTFail("No trip data available")
            return
        }
        
        print(data.arrival)
        XCTAssertEqual(data.state.get(), "Abfahrt in 10s")
        XCTAssertEqual(data2.state.get(), "Abfahrt in 9s")

    }
    
    func testArrivalDateBeforeDeparture2() {
        
        self.dataProvider.setTrip(withName: "wfb_trip_bielefeld")
        self.dataProvider.update()
        self.reloadTrips()
        self.controller.GRACE_PERIOD = 900
        
        guard let initialTrip = self.initialTrip else {
            XCTFail("Failed to get trip")
            return
        }
        
        self.controller.setCurrentLocation(location: initialTrip.locationArray.first!.coords)
        
        guard let journeyStart = self.initialTrip?.departure else {
            XCTFail("Could not get departure date")
            return
        }
        
        self.timeProvider.date = journeyStart.addingTimeInterval(-500)
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        controller.pause()
        self.timeProvider.date = journeyStart.addingTimeInterval(-499)
        self.delegate.updated = XCTestExpectation()
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        controller.pause()
        guard let (_, data, _) = delegate.updatedArray.first else {
            XCTFail("No trip data available")
            return
        }
        
        guard let (_, data2, _) = delegate.updatedArray.last else {
            XCTFail("No trip data available")
            return
        }
        
        print(data.arrival)
        print(data2.arrival)
        let arrivalTimeDiff = data.arrival - data2.arrival
        XCTAssertTrue(arrivalTimeDiff == 1 , "Arrival time must decrease in one-second-interval (Is: \(arrivalTimeDiff))")

    }
    
    //MARK: - Delay
    
    /**
     This train has over 2h delay. It should depart from bs hbf
     */
    func testDistanceFromUserWithDelay() {
        self.dataProvider.setTrip(withName: "ice_huge_delay")
        self.dataProvider.update()
        self.reloadTrips()
        
        guard let initialTrip = self.initialTrip else {
            XCTFail("Failed to get trip")
            return
        }
        
        self.controller.setCurrentLocation(location: CLLocation(latitude: 52.243616, longitude: 10.514395))

        var components = DateComponents()
        components.second = 59
        components.hour = 20
        components.minute = 17
        components.day = 18
        components.month = 9
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
        
        XCTAssertEqual(data.state.get(withTimeGenerator: self.timeProvider), "Stopped for 1s at Braunschweig Hbf")
        XCTAssertEqual(Int(data.distance!),-2305)
    }
    
    func testDelayForNextStation() {
        self.dataProvider.setTrip(withName: "bs_delay")
        self.dataProvider.update()
        self.reloadTrips()
        
        guard let initialTrip = self.initialTrip else {
            XCTFail("Failed to get trip")
            return
        }
        
        self.controller.setCurrentLocation(location: initialTrip.locationArray.first!.coords)
        
        var components = DateComponents()
        components.second = 0
        components.hour = 0
        components.minute = 0
        components.day = 14
        components.month = 9
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
        
        XCTAssertEqual(data.state.get(), "Braunschweig Hbf")
        XCTAssertEqual(data.delay,300)
    }
    
    /**
     User is at Vechelde, Train departed after 1 Second and arrives at BS with +25, time to user should still be -1
     */
    func testTimeToUserIfDelay() {
        self.dataProvider.setTrip(withName: "wfb_trip_25_min_delay_to_bs")
        self.dataProvider.update()
        self.reloadTrips()

        self.controller.setCurrentLocation(location: CLLocation(latitude: 52.2595084, longitude: 10.361784))
        
        var components = DateComponents()
        components.second = 00
        components.hour = 17
        components.minute = 17
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
        
        // Train just arrived at this stop
        XCTAssertEqual(data.state.get(withTimeGenerator: self.timeProvider), "Stopped for 60s at Vechelde")
        XCTAssertEqual(data.delay,1500)
        XCTAssertEqual(data.arrival,0.0)
        
        components = DateComponents()
        components.second = 1
        components.hour = 17
        components.minute = 18
        components.day = 12
        components.month = 6
        components.year = 2020
        guard let secondDate = Calendar.current.date(from: components) else {
            XCTFail("Could not parse date")
            return
        }
        
        self.timeProvider.date = secondDate

        self.delegate.updated = XCTestExpectation(description: "Should trigger the update method a second time")
       
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        controller.pause()
        
        guard let (_, secondData, _) = delegate.updatedArray.last else {
            XCTFail("No trip data available")
            return
        }
        
        // Train departed one second ago
        XCTAssertEqual(secondData.state.get(withTimeGenerator: self.timeProvider), "Braunschweig Hbf")
        XCTAssertEqual(secondData.delay,1500)
        XCTAssertEqual(secondData.arrival,-61.0)
        
    }
    
    //MARK:- UpdateMechanism
    
    // Remaining journeys after fetch should still be there, but should have updated data, like delay etc
    func testRemainingJourneys() {
        let mockProvider = MockTrainDataTimeFrameProviderSimple()
        
        let trip = TimeFrameTrip(withDeparture: Date(), andName: "TestTrip", andPolyline: Array.init(), andLocationMapping: Array.init(), andID: "12", andDestination: "Hell", andDelay: 0)
        
        let tripUpdated = TimeFrameTrip(withDeparture: Date(), andName: "TestTrip", andPolyline: Array.init(), andLocationMapping: Array.init(), andID: "12", andDestination: "Hell", andDelay: 9001)
        
        mockProvider.trips = [tripUpdated]
        
        controller.setDataProvider(withProvider: TripProvider(mockProvider))
        
        controller.trips = [trip]
        controller.update()
        
        controller.setDataProvider(withProvider: TripProvider(MockTrainDataTimeFrameProvider(withFile: "")))
        
        XCTAssertEqual(controller.trips.count, 1)
        
        guard let newTrip = controller.trips.first else {
            XCTFail("No trip found after update")
            return
        }
        
        XCTAssertEqual(newTrip.delay, 9001)
        
    }
    
    //MARK: - Auto Refresh
    
    //After single trip-refresh, the ice should have more delay
    func testAutoRefreshNewDelay() {
        self.dataProvider.setTrip(withName: "bs_delay")
        self.dataProvider.update()
        self.reloadTrips()
        
        guard let initialTrip = self.initialTrip else {
            XCTFail("Failed to get trip")
            return
        }
        
        self.controller.setCurrentLocation(location: initialTrip.locationArray.first!.coords)
        
        var components = DateComponents()
        components.second = 0
        components.hour = 0
        components.minute = 0
        components.day = 14
        components.month = 9
        components.year = 2020
        guard let date = Calendar.current.date(from: components) else {
            XCTFail("Could not parse date")
            return
        }
        
        self.timeProvider.date = date
        
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        guard let (_, data, _) = delegate.updatedArray.first else {
            XCTFail("No trip data available")
            return
        }
        
        XCTAssertEqual(data.state.get(), "Braunschweig Hbf")
        XCTAssertEqual(data.delay,300)
        
        self.dataProvider.setTrip(withName: "bs_delay_more_delay")
        
        self.delegate.updated = XCTestExpectation(description: "Should return updated delay")
        controller.pause()
        controller.refreshSelected(trips: [initialTrip])
        controller.start()
        wait(for: [self.delegate.updated], timeout: 10)
        controller.pause()
        
        guard let (_, newData, _) = delegate.updatedArray.last else {
            XCTFail("No trip data available")
            return
        }
        
        XCTAssertEqual(newData.state.get(), "Braunschweig Hbf")
        XCTAssertEqual(newData.delay,560)
    }
    
    //MARK: - Time Calculation with Delay
    
    //MARK: - Distance
    
    /**
     Thirs train ride should have all positive distances because the train is in front of user
     */
    func testDistancePositiveValue() {
        self.dataProvider.setTrip(withName: "ice_huge_delay")
        self.dataProvider.update()
        self.reloadTrips()
        
        guard let initialTrip = self.initialTrip else {
            XCTFail("Failed to get trip")
            return
        }
        
        self.controller.setCurrentLocation(location: CLLocation(latitude: 52.243616, longitude: 10.514395))

        var components = DateComponents()
        components.second = 45
        components.hour = 20
        components.minute = 11
        components.day = 18
        components.month = 9
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
        
        XCTAssertEqual(data.state.get(withTimeGenerator: self.timeProvider), "Stopped for 1s at Braunschweig Hbf")
        XCTAssertEqual(Int(data.distance!),-2348)
    }
    
    

}
