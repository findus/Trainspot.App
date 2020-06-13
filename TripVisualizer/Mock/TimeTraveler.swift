//
//  TimeTraveler.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 13.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

// https://www.swiftbysundell.com/articles/time-traveling-in-swift-unit-tests/
public class TimeTraveler {
    public var date = Date()
    
    public init(){}

    public func travel(by timeInterval: TimeInterval) {
        date = date.addingTimeInterval(timeInterval)
    }

    public func generateDate() -> Date {
        return date
    }
}
