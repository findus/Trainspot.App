//
//  TrainDataProviderProtocol.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

protocol TrainDataProviderProtocol {
    associatedtype TripData: Trip
    func getAllTrips() -> Array<TripData>
}
