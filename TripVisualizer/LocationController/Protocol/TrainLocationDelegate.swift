//
//  TrainLocationDelegate.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

public enum TrainState {
    case DepartsToLate
    case WaitForStart(TimeInterval)
    case Ended
    case Stopped(Date,String)
    case Driving(String?)
    
    public func get() -> String {
        switch self {
        case .WaitForStart(let seconds):
            return "Departs in \(Int(seconds))s"
        case .Ended:
            return "Ended"
        case .Driving(let nextStop):
            return "\(nextStop ?? "")"
        case .Stopped(let date, let station):
            //TODO timetravel
            return "Stopped for \(Int(date.timeIntervalSince(Date())))s at \(station)"
        case .DepartsToLate:
            return "Departs to late"
        }
    }
}

public struct TripData {
    public let location: CLLocation?
    public let state: TrainState
    public let arrival: TimeInterval
    public var distance: Double?
}

public protocol TrainLocationDelegate: NSObject {
    var id: String { get }
    func trainPositionUpdated(forTrip trip: Trip, withData data: TripData, withDuration duration: Double) -> Void
    func removeTripFromMap(forTrip trip: Trip) -> Void
    func drawPolyLine(forTrip: Trip) -> Void
    func onUpdateStarted()
    func onUpdateEnded()
}
