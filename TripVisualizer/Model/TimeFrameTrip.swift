//
//  TimeFrameTrip.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 06.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

public class TimeFrameTrip: Trip, Hashable {
    
    public var tripId: String
    public var departure: Date
    public var journey: Journey?
    public var polyline: Array<MapEntity>
    public var locationArray: Array<Feature>
    public var destination: String
 
    public let name: String
    public let delay: Int?
            
    var counter = 0
    
    public init(withDeparture time: Date, andName name: String, andPolyline line: Array<MapEntity>, andLocationMapping mapping: Array<Feature>, andID id: String, andDestination destination: String, andDelay delay: Int?) {
        self.departure = time
        self.polyline = line
        self.name = name
        self.journey = nil
        self.locationArray = mapping
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
        let shortestPosition = self.shortestDistanceArrayPosition(forUserLocation: loc)
        let trainPosition = self.currentTrainPosition()
        
        if trainPosition ?? self.locationArray.count > shortestPosition {
            return true
        }
        
        return false
    }
    
    /*
     Gets tracks shortest distance to the user, so that we can calulcate the approximate arrival of the train
     */
    public func shorttestDistanceToTrack(forUserLocation loc : CLLocation) -> Double {
        return self.locationArray[self.shortestDistanceArrayPosition(forUserLocation: loc)].coords.distance(from: loc)
    }
    
    public func shortestDistanceArrayPosition(forUserLocation loc: CLLocation) -> Int {
        let distances = locationArray.map { $0.coords.distance(from: loc) }

        var arrayPosition = 0
        for (index, distance) in distances.enumerated() {
            if distances[arrayPosition] > distance {
                arrayPosition = index
            }
        }

        return arrayPosition
    }
    
    /**
     Returns the current position of the train, which is the nth position inside the array, returns empty if array bounds are exceeded
     */
    public func currentTrainPosition() -> Int? {
        counter+=1
        return counter
    }
    
}

extension TimeFrameTrip {
    public static func == (lhs: TimeFrameTrip, rhs: TimeFrameTrip) -> Bool {
        lhs.tripId == rhs.tripId
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(self.tripId)
    }
}
