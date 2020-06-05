//
//  RadarTrip.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

class RadarTrip: Trip {
   
    let fetchTime: Date
    /**
            A line, that represents the trains approximate location for the next 45 Minutes, 61 entries ~every 45 Seconds
     */
    let polyline: Array<MapEntity>
    let name: String
    
    let journey: Journey?
    
    let type: String
    
    public init(withFetchTime time: Date, andName name: String, andLines line: Array<MapEntity>, isType type: String) {
        self.fetchTime = time
        self.polyline = line
        self.name = name
        self.journey = nil
        self.type = type
    }
    
    /**
     Checks, if the train is heading towards the user, or still passed the location
     */
    func isParting(forUserLocation loc: CLLocation) -> Bool {
        let shortestPosition = self.shortestDistanceArrayPosition(forUserLocation: loc)
        let trainPosition = self.currentTrainPosition()
        
        if trainPosition ?? self.polyline.count > shortestPosition {
            return true
        }
        
        return false
    }
    
    /*
     Gets tracks shortest distance to the user, so that we can calulcate the approximate arrival of the train
     */
    func shorttestDistanceToTrack(forUserLocation loc : CLLocation) -> Double {
        return polyline[self.shortestDistanceArrayPosition(forUserLocation: loc)].location.distance(from: loc)
    }
    
    private func shortestDistanceArrayPosition(forUserLocation loc: CLLocation) -> Int {
        let distances = polyline.map { $0.location.distance(from: loc) }
        
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
        let date = self.fetchTime
        let now = Date.init()
        let diff = now.timeIntervalSince(date)
        if ceil(diff) >= T_45_MINUTES {
            print("RadarTrip \(self.name) exceeded max time")
            return nil
        } else {
            let arrayPosition = Int(floor( ( (1 / DURATION ) * ceil(diff) ) )  + 1)
            print("Returning \(arrayPosition) for \(self.name)")
            return arrayPosition
        }
    }
    
}
