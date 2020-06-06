//
//  TimeFrameTrip.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 06.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

class TimeFrameTrip: Trip {
    
    var departure: Date
    var journey: Journey?
    var polyline: Array<MapEntity>
    var locationArray: Array<Feature>
 
    let name: String
            
    var counter = 0
    
    public init(withDeparture time: Date, andName name: String, andPolyline line: Array<MapEntity>, andLocationMapping mapping: Array<Feature>) {
        self.departure = time
        self.polyline = line
        self.name = name
        self.journey = nil
        self.locationArray = mapping
    }
    
    func positionAtTime(date: Date) {
        
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
