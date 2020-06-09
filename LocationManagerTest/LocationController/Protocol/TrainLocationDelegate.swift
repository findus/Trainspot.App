//
//  TrainLocationDelegate.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

enum TrainState {
    case WaitForStart
    case Ended
    case Stopped(til: Date)
    case Driving
}

struct TripData {
    let location: CLLocation
    let state: TrainState
    let nextStop: String
}

protocol TrainLocationDelegate: NSObject {
    var id: String { get }
    func trainPositionUpdated(forTrip trip: Trip, withData data: TripData, withDuration duration: Double) -> Void
    func removeTripFromMap(forTrip trip: Trip) -> Void
    func drawPolyLine(forTrip: Trip) -> Void
}
