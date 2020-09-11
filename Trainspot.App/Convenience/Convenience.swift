//
//  Convenience.swift
//  LocationManagerTest
//
//  Created by Philipp on 15.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

public func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int, Bool) {
    if seconds > 0 {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60, false)
        
    } else {
        return ((seconds / 3600) * -1 , ((seconds % 3600) / 60) * -1, ((seconds % 3600) % 60) * -1, true)
    }
}
