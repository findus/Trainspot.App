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
    
    public func get(withTimeGenerator generator: TimeTraveler? = nil) -> String {
        switch self {
        case .WaitForStart(let seconds):
            return "Abfahrt in \(Int(seconds))s"
        case .Ended:
            return "Ende"
        case .Driving(let nextStop):
            return "\(nextStop ?? "")"
        case .Stopped(let date, let station):
            if generator != nil {
                return "Stopped for \(Int(date.timeIntervalSince(generator!.generateDate())))s at \(station)"
            } else {
                return "Stopped for \(Int(date.timeIntervalSince(Date())))s at \(station)"
            }
        case .DepartsToLate:
            return "Departs to late"
        }
    }
}

/**
Data Object that holds information about the trip at a certain amount of time
*/
public struct TripData {
    public let location: CLLocation?
    public let state: TrainState
    public let arrival: TimeInterval
    public var distance: Double?
    // Delay on next stopover
    public var delay: Int
}

/**
 Protocol with callback methods that a controller emits
 */
public protocol TrainLocationDelegate: NSObject {
    var id: String { get }
    /**
     Callback that gets triggered inside the Trainlocationcontrollers, most likely by a timer. The callback data includes the train position and additional data to display
     The trigger interval is configurable inside the controller
     */
    func trainPositionUpdated(forTrip trip: Trip, withData data: TripData, withDuration duration: Double) -> Void
    func removeTripFromMap(forTrip trip: Trip) -> Void
    func drawPolyLine(forTrip: Trip) -> Void
    func onUpdateStarted()
    func onUpdateEnded(withResult result: Result)
}
