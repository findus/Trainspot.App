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
      
        // Drop the last path because that is the the user is on
        let distance = trip
            .locationArray[section.priorStopOverArrayPosition...userPositionInArray].dropLast()
            .map({$0.distanceToNext}).reduce(0, +)
        
        //Get the time the train needs to get to the user
        let duration = OffsetCalculator().getTimeForDistance(distance, forSection: section)
        
        // Add this duration to the departure date of the last stopover
        let departure = (trip.locationArray[section.priorStopOverArrayPosition] as! StopOver).departure
        
        //And return it
        return departure!.addingTimeInterval(duration)
    }
}
