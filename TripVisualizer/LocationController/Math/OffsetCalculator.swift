//
//  OffsetCalculator.swift
//  TripVisualizer
//
//  Created by Philipp Hentschel on 21.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

class OffsetCalculator {
    /**
     
     */
    private var ACCELERATION_TIME = 90.0
    private var TRAIN_ACCELERATION = 0.4
    private var trip: TimeFrameTrip?
    
    /**
     Section Between 2 Stops
     */
    struct Section {
        // Lenth in Meters
        var length: Double
        // Duration in Seconds
        var duration: Double
    }

    /**
     This class tries to mimic an acceleration curve.
     At the moment it just assumes, that the train reaches vmax after 90 seconds, and brakes 90 seconds before the next stop.
     For shorter sections we assume that 10% of the sections is needed to reach vmax, also basix acceleration is set to a little highler value to prevent overlappibg curves.
     This might get a litte more accurate positions in real life, because with linear plotting, the train is always a little off because of its acceleration phase.
     
     Additional Featuers that might make sense: Different Curves for ICE/Regional trains,
     
     //https://github.com/findus/Trainspot.App/issues/14
     */
    public func getPositionForTime(_ time: Double, forSection section: Section) -> Double {
        
        /**
         Use other acceleration curve data for shorter trips and just assume that the train reaches vmax after 10% of the section is completed
         **/
        if section.duration < 230 {
            
            self.ACCELERATION_TIME = section.duration * 0.10
            self.TRAIN_ACCELERATION = 0.8
        }
        
        /**
         If the section is longer than 230 seconds use 90 Seconds as fixed value for now
         Based on the time the function looks in which phase the train is currently in and calculates/returns a position.
         */
        if time > 0 && time <= ACCELERATION_TIME {
            //Train is in acceleration Phase
            
            // Acceleration per time formula
            let result = (0.5*TRAIN_ACCELERATION)*pow(time, 2)
            return result < 0 ? 0.0 : result
        } else if time >= (section.duration - ACCELERATION_TIME) {
            //Train is in braking Phase
           
            let result = (0.5*(-TRAIN_ACCELERATION))*pow((time - section.duration), 2) + section.length
            return result < 0 ? 0.0 : result
        } else {
            //Train is driving with vmax
            
            let halfTime = (section.duration/2)
            
            let startingPointY = getPositionForTime(ACCELERATION_TIME, forSection: section)
            let middleOfSection = halfTime*(section.length / section.duration)
            
            // f(x) mx+b
            let m = (middleOfSection - startingPointY) / (halfTime - ACCELERATION_TIME)
            let b = startingPointY - (m*ACCELERATION_TIME)
            
            //Position
            let result = (m*time)+b
            return result < 0 ? 0.0 : result
        }
    }
}
