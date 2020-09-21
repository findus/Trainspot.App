//
//  AccelerationSimulatorTest.swift
//  TripVisualizerTests
//
//  Created by Philipp Hentschel on 21.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import XCTest
@testable import TripVisualizer

class AccelerationSimulatorTest: XCTestCase {


    func testExample() throws {
        let calculator = OffsetCalculator()
        
        let section = OffsetCalculator.Section(length: 14000, duration: 600)
        for n in 0...600 {
            print("\(n),\(calculator.getPositionForTime(Double(n), forSection: section))")
        }
    }


}
