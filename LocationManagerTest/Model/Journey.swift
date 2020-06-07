//
//  Journey.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

struct Journey: Hashable {
    var from_id: String    
    var from: String
    var to: String
    var tripID: String
    var when: Date
    
    var hashValue: Int {
        return tripID.hashValue
    }
    
    static func == (lhs: Journey, rhs: Journey) -> Bool {
        return lhs.tripID == rhs.tripID
    }
    
}
