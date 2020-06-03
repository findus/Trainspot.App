//
//  Journey.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

class Journey {
    
    let fetchTime: Date
    /**
            A line, that represents the trains approximate location for the next 45 Minutes, 61 entries ~every 45 Seconds
     */
    let line: Array<MapEntity>
    let name: String
    
    func shorttestDistanceToTrack(forUserLocation loc : CLLocation) -> Double {
        let distances = line.map { $0.location.distance(from: loc) }
        
        
        var arrayPosition = 0
        for (index, distance) in distances.enumerated() {
            if distances[arrayPosition] > distance {
                arrayPosition = index
            }
        }
        
        return line[arrayPosition].location.distance(from: loc)
    }
    
    public init(withFetchTime time: Date, andName name: String, andLines line: Array<MapEntity>) {
        self.fetchTime = time
        self.line = line
        self.name = name
    }
    
    
}
