//
//  Userprefs.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 10.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

class UserPrefs {
    private static let timeOffset = "TIME_OFFSET"
    
    static func getTimeOffset() -> Int {
        UserDefaults.standard.integer(forKey: timeOffset)
    }
    
    static func setTimeOffset(_ offset: Int) {
        UserDefaults.standard.set(offset, forKey: timeOffset)
        UserDefaults.standard.synchronize()
    }
    
    private static let selectedStation = "SELECTED_STATION"
    
    static func getSelectedStation() -> (String,String)? {
        UserDefaults.standard.object(forKey: selectedStation) as? (String,String)
    }
    
    static func setSelectedStation(_ stationData: (name:String,ibnr: String)) {
        UserDefaults.standard.set(stationData, forKey: selectedStation)
        UserDefaults.standard.synchronize()
    }
}
