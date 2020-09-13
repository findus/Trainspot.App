//
//  TrainDataProviderProtocol.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

public protocol TrainDataProviderProtocol {
    associatedtype TripData
    func getAllTrips() -> Array<TripData>
    func update() -> Void
    func setDeleate(delegate: TrainDataProviderDelegate)
}

public enum Result {
    case success
    case error(String)
}

//TODO Somehow pass the associated trip type as argument, but currently not sure how to realize this
public protocol TrainDataProviderDelegate {
    func onTripsUpdated(result: Result)
}
