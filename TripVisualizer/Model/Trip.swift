//
//  Trip.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

public protocol Trip {
    
    var tripId: String { get set }
       
    var departure: Date { get }
    /**
            A line, that represents the trains approximate location for the next 45 Minutes, 61 entries ~every 45 Seconds
     */
    var polyline: Array<MapEntity> { get }
    
    var name: String { get }
    
    var journey: Journey? { get }
    
    var destination: String { get }
    
    var delay: Int? { get }
    
    /**
     Checks, if the train is heading towards the user, or still passed the location
     */
    func isParting(forUserLocation loc: CLLocation) -> Bool
    
    /*
     Gets tracks shortest distance to the user, so that we can calulcate the approximate arrival of the train
     */
    func shorttestDistanceToTrack(forUserLocation loc : CLLocation) -> Double
    
    /**
     Returns the current position of the train, which is the nth position inside the array, returns empty if array bounds are exceeded
     */
    func currentTrainPosition() -> Int?
    
    func nearestTrackPosition(forUserLocation loc : CLLocation) -> CLLocationCoordinate2D

}
