//
//  CSVParserTests.swift
//  CSVParserTests
//
//  Created by Philipp Hentschel on 10.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import XCTest
@testable import CSVParser

class CSVParserTests: XCTestCase {

    func testStation() {
        let results = CsvReader.shared.getStationInfo(withContent: "Braunschweig")
        XCTAssertTrue(results?.count == 2, "File should return 2 result sets")
        XCTAssertEqual(results?[0].ibnr, "8000049")
        XCTAssertEqual(results?[0].stationName, "Braunschweig Hbf")

    }
    
}
