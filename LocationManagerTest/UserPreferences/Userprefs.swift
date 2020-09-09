//
//  Userprefs.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 10.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

class UserPrefs {
    static let timeOffset = "TIME_OFFSET"
    static let stationId = "STATION_ID"
    
    static func getTimeOffset() -> Int {
        UserDefaults.standard.integer(forKey: timeOffset)
    }
    
    static func setTimeOffset(_ offset: Int) {
        UserDefaults.standard.set(offset, forKey: timeOffset)
    }
}
