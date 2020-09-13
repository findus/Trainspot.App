//
//  Journey.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

public struct Journey: Hashable {
    var from_id: String    
    var from: String
    var to: String
    var tripID: String
    var when: Date
    var name: String
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.tripID)
    }
    
    public static func == (lhs: Journey, rhs: Journey) -> Bool {
        return lhs.tripID == rhs.tripID
    }
    
}
