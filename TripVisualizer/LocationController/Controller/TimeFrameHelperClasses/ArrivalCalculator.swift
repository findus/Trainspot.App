//
//  ArrivalCalculator.swift
//  TripVisualizer
//
//  Created by Philipp Hentschel on 25.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

class ArrivalCalculator<T: TimeFrameTrip> {
    
    
    public func getArrivalInSeconds(forTrip trip: T,
                                    forSection section: OffsetCalculator.Section,
                                    userPositionInArray: Int,
                                    dateGenerator: () -> Date = Date.init) -> Date {
      
        // Drop the last path because that is the one the user is on
        let distance = trip
            .locationArray[section.priorStopOverArrayPosition...userPositionInArray].dropLast()
            .map({$0.distanceToNext}).reduce(0, +)
        
        //Get the time the train needs to get to the user
        let duration = OffsetCalculator().getTimeForDistance(distance, forSection: section)
        
        // Add this duration to the departure date of the last stopover
        let startingPointStopOver = (trip.locationArray[section.priorStopOverArrayPosition] as! StopOver)
        
        // If user is on same position as stopover use arrival date
        if section.priorStopOverArrayPosition == userPositionInArray && startingPointStopOver.arrival != nil {
           
            let arrival = startingPointStopOver.arrival
            return arrival!.addingTimeInterval(duration)
        } else {
           
            let departure = startingPointStopOver.departure
            return departure!.addingTimeInterval(duration)
          
        }
        
    }
}
