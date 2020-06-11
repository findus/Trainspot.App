//
//  TimeFrameTrip.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 06.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

class TimeFrameTrip: Trip, Hashable {
    
    var tripId: String
    var departure: Date
    var journey: Journey?
    var polyline: Array<MapEntity>
    var locationArray: Array<Feature>
    var destination: String
 
    let name: String
            
    var counter = 0
    
    public init(withDeparture time: Date, andName name: String, andPolyline line: Array<MapEntity>, andLocationMapping mapping: Array<Feature>, andID id: String, andDestination destination: String) {
        self.departure = time
        self.polyline = line
        self.name = name
        self.journey = nil
        self.locationArray = mapping
        self.tripId = id
        self.destination = destination
    }
    
    func positionAtTime(date: Date) {
        
    }
    
    /**
     Checks, if the train is heading towards the user, or still passed the location
     */
    func isParting(forUserLocation loc: CLLocation) -> Bool {
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
    func shorttestDistanceToTrack(forUserLocation loc : CLLocation) -> Double {
        return self.locationArray[self.shortestDistanceArrayPosition(forUserLocation: loc)].coords.distance(from: loc)
    }
    
    private func shortestDistanceArrayPosition(forUserLocation loc: CLLocation) -> Int {
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
    func currentTrainPosition() -> Int? {
        counter+=1
        return counter
    }
    
}

extension TimeFrameTrip {
    static func == (lhs: TimeFrameTrip, rhs: TimeFrameTrip) -> Bool {
        lhs.tripId == rhs.tripId
    }
    
    func hash(into hasher: inout Hasher) {
        return hasher.combine(self.tripId)
    }
}
