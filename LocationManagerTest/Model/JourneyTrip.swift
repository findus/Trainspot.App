//
//  RadarTrip.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

protocol Feature {
    var coords: CLLocation { get set }
}

struct Path: Feature {
    var coords: CLLocation

    //animation data
    var duration: Int?
    var lastBeforeStop: Bool = false
}

struct StopOver: Feature {

    var name: String
    var coords: CLLocation

    var arrival: Date?
    var departure: Date?
}

enum VehicleState {
    case Driving
    case Stopping
    case Accelerating
}
    
struct AnimationData {
    var vehicleState: VehicleState
    var duration: Double
}

struct Timeline {
    var name: String
    var line: Array<Feature>
    var animationData: Array<AnimationData>
    var departure: Date
}

class JourneyTrip: Trip, Hashable {
    
    var atStation: Bool = false
   
    var polyline: Array<MapEntity>
 
    let departure: Date
    let timeline: Timeline
    let name: String
    
    let journey: Journey?
        
    var counter = 0
    
    public init(withDeparture time: Date, andName name: String, andTimeline timeline: Timeline, andPolyline line: Array<MapEntity>) {
        self.departure = time
        self.polyline = line
        self.name = name
        self.journey = nil
        self.timeline = timeline
    }
    
    /**
     Checks, if the train is heading towards the user, or still passed the location
     */
    func isParting(forUserLocation loc: CLLocation) -> Bool {
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
    func shorttestDistanceToTrack(forUserLocation loc : CLLocation) -> Double {
        //return line[self.shortestDistanceArrayPosition(forUserLocation: loc)].location.distance(from: loc)
        return 0.0
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
        return 0
    }
    
    /**
     Returns the current position of the train, which is the nth position inside the array, returns empty if array bounds are exceeded
     */
    func currentTrainPosition() -> Int? {
        counter+=1
        return counter
    }
    
}

extension JourneyTrip {
    static func == (lhs: JourneyTrip, rhs: JourneyTrip) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
    }
}
