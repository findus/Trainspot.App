//
//  RadarTrip.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

public protocol Feature {
    var coords: CLLocation { get set }
    var departure: Date? { get set }
    var durationToNext: Double? { get set }
    var distanceToNext: Double { get set }
}

public struct Path: Feature {
    public var distanceToNext: Double
    public var durationToNext: Double?
    
    public var departure: Date?
    public var coords: CLLocation

    //animation data
    public var lastBeforeStop: Bool = false
}

public struct StopOver: Feature {
    public var distanceToNext: Double
    public var durationToNext: Double?

    public var name: String
    public var coords: CLLocation

    public var arrival: Date?
    public var departure: Date?
    
    public var arrivalDelay: Int?
    public var departureDelay: Int?
}

public enum VehicleState {
    case Driving
    case Stopping
    case Accelerating
}
    
public struct AnimationData {
    public var vehicleState: VehicleState
    public var duration: Double
}

public struct Timeline {
    public var name: String
    public var line: Array<Feature>
    public var animationData: Array<AnimationData>
    public var departure: Date
}

public class JourneyTrip: Trip, Hashable {
   
    public var destination: String
    
    public var tripId: String

    public var atStation: Bool = false
   
    public var polyline: Array<MapEntity>
 
    public let departure: Date
    public let timeline: Timeline
    public let name: String
    
    public let journey: Journey?
    
    public let delay: Int?
        
    var counter = 0
    
    public init(withDeparture time: Date, andName name: String, andTimeline timeline: Timeline, andPolyline line: Array<MapEntity>, andID id: String, andDestination destination: String, andDelay delay: Int?) {
        self.departure = time
        self.polyline = line
        self.name = name
        self.journey = nil
        self.timeline = timeline
        self.tripId = id
        self.destination = destination
        self.delay = delay
    }
    
    func positionAtTime(date: Date) {
        
    }
    
    /**
     Checks, if the train is heading towards the user, or still passed the location
     */
    public func isParting(forUserLocation loc: CLLocation) -> Bool {
//        let shortestPosition = self.shortestDistanceArrayPosition(forUserLocation: loc)
//        let trainPosition = self.currentTrainPosition()
//
//        if trainPosition ?? self.line.count > shortestPosition {
//            return true
//        }
//
        return false
    }
    
    /*
     Gets tracks shortest distance to the user, so that we can calulcate the approximate arrival of the train
     */
    public func shorttestDistanceToTrack(forUserLocation loc : CLLocation) -> Double {
        //return line[self.shortestDistanceArrayPosition(forUserLocation: loc)].location.distance(from: loc)
        fatalError("Not yet implemented")
    }
    
    private func shortestDistanceArrayPosition(forUserLocation loc: CLLocation) -> Int {
//        let distances = line.map { $0.location.distance(from: loc) }
//
//        var arrayPosition = 0
//        for (index, distance) in distances.enumerated() {
//            if distances[arrayPosition] > distance {
//                arrayPosition = index
//            }
//        }
//
//        return arrayPosition
        fatalError("Not yet implemented")
    }
    
    public func nearestTrackPosition(forUserLocation loc : CLLocation) -> CLLocationCoordinate2D {
        fatalError("Not yet implemented")
    }

    
    /**
     Returns the current position of the train, which is the nth position inside the array, returns empty if array bounds are exceeded
     */
    public func currentTrainPosition() -> Int? {
        counter+=1
        return counter
    }
    
}

extension JourneyTrip {
    public static func == (lhs: JourneyTrip, rhs: JourneyTrip) -> Bool {
        return lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
    }
}
