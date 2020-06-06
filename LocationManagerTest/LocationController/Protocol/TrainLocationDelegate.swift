//
//  TrainLocationDelegate.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

protocol TrainLocationDelegate: NSObject {
    func trainPositionUpdated(forTrip trip: Trip, toPosition: CLLocation, withDuration duration: Double) -> Void
    func removeTripFromMap(forTrip trip: Trip) -> Void
    func drawPolyLine(forTrip: Trip) -> Void
}
