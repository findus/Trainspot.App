//
//  TimeFrameControllerTests.swift
//  LocationManagerTestTests
//
//  Created by Philipp Hentschel on 13.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

import XCTest

@testable import LocationManagerTestMock

class TimeFrameControllerTests: XCTestCase {

    var controller = TrainLocationTripByTimeFrameController()
    var dataProvider = MockTrainDataTimeFrameProvider()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.dataProvider = MockTrainDataTimeFrameProvider()
        controller = TrainLocationTripByTimeFrameController()
        controller.setDataProvider(withProvider: TripProvider(dataProvider))
        
        self.dataProvider.update()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testMinPosition() {
        print(controller.trips)
    }

}
