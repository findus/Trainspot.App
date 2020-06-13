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
    case Stopped(Date)
    case Driving(String?)
    
    func get() -> String {
        switch self {
        case .WaitForStart:
            return "Wait for Start"
        case .Ended:
            return "Ended"
        case .Driving(let nextStop):
            return "\(nextStop ?? "")"
        case .Stopped(let date):
            return "Stopped for \(Int(date.timeIntervalSince(Date())))s"
        }
    }
}

struct TripData {
    let location: CLLocation?
    let state: TrainState
    let arrival: TimeInterval
    var distance: Double?
}

protocol TrainLocationDelegate: NSObject {
    var id: String { get }
    func trainPositionUpdated(forTrip trip: Trip, withData data: TripData, withDuration duration: Double) -> Void
    func removeTripFromMap(forTrip trip: Trip) -> Void
    func drawPolyLine(forTrip: Trip) -> Void
}
