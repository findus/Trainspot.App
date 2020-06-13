//
//  TimeTraveler.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 13.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

// https://www.swiftbysundell.com/articles/time-traveling-in-swift-unit-tests/
class TimeTraveler {
    var date = Date()

    func travel(by timeInterval: TimeInterval) {
        date = date.addingTimeInterval(timeInterval)
    }

    func generateDate() -> Date {
        return date
    }
}
