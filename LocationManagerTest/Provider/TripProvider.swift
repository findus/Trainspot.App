//
//  TripProvider.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 05.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

class TripProvider<T : Trip> : TrainDataProviderProtocol {
    
    var trips: Array<T>
    
    init<P: TrainDataProviderProtocol>(_ provider: P) where P.TripData == T {
         trips = provider.getAllTrips()
    }
    
    func getAllTrips() -> Array<T> {
        return trips
    }
    
    func update() {
        
    }

}
