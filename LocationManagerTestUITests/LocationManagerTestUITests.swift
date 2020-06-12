//
//  LocationManagerTestUITests.swift
//  LocationManagerTestUITests
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import XCTest
import SwiftyJSON
import CoreLocation

@testable import LocationManagerTest

class LocationManagerTestUITests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        guard
            let filePath = Bundle(for: type(of: self)).path(forResource: "hafas_test_json", ofType: "json"),
            let data = NSData(contentsOfFile: filePath) else {
                XCTFail()
                return
        }
        
        let json = try! JSON(data: data as Data)
        //let coords = json[0]["polyline"]["features"].arrayValue.map { MapEntity(name: "lol", tripId: <#String#>, location: CLLocation(latitude: $0["geometry"]["coordinates"][0].doubleValue, longitude: $0["geometry"]["coordinates"][1].doubleValue ))  }
        print(coords)
        
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                XCUIApplication().launch()
            }
        }
    }
}
