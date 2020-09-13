//
//  Userprefs.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 10.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

public struct StationInfo: Codable {
    public init(_ name: String,_ ibnr: String) {
        self.name = name
        self.ibnr = ibnr
    }
    public var name: String
    public var ibnr: String
}

public class UserPrefs {
    
    private static let maxDistance = "MAX_DISTANCE"
    
    public static func getMaxDistance() -> Int {
        let distance = UserDefaults.standard.integer(forKey: maxDistance)
        if distance < 100 {
            return 100
        } else {
            return distance
        }
    }
    
    public static func setMaxDistance(_ offset: Int) {
        UserDefaults.standard.set(offset, forKey: maxDistance)
        UserDefaults.standard.synchronize()
    }
    
    private static let timeOffset = "TIME_OFFSET"

    
    public static func getTimeOffset() -> Int {
        UserDefaults.standard.integer(forKey: timeOffset)
    }
    
    public static func setTimeOffset(_ offset: Int) {
        UserDefaults.standard.set(offset, forKey: timeOffset)
        UserDefaults.standard.synchronize()
    }
    
    private static let selectedStation = "SELECTED_STATION"
    
    public static func getSelectedStation() -> StationInfo {
        guard let data = UserDefaults.standard.data(forKey: selectedStation) else {
            return StationInfo("Braunschweig Hbf", "8000049")
        }
        return try! PropertyListDecoder().decode(StationInfo.self, from: data)
    }
    
    public static func setSelectedStation(_ stationData: StationInfo) {
        let data = try! PropertyListEncoder().encode(stationData)
        UserDefaults.standard.set(data, forKey: selectedStation)
        UserDefaults.standard.synchronize()
    }
    
    private static let _useRealLocation = "USE_USER_SET_LOCATION"
    
    public static func getManualPositionDetermination() -> Bool {
        return UserDefaults.standard.bool(forKey: _useRealLocation)
    }
    
    public static func setManualPositionDetermination(_ useRealLocation: Bool) {
        UserDefaults.standard.set(useRealLocation, forKey: _useRealLocation)
        UserDefaults.standard.synchronize()
    }
}
