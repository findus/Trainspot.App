//
//  MapEntity.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import UIKit
import CoreLocation

public struct MapEntity {
    public var name: String
    public var tripId: String
    public var location: CLLocation
    
    public init(name: String, tripId: String, location: CLLocation) {
        self.name = name
        self.tripId = tripId
        self.location = location
    }
}
