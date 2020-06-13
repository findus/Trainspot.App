//
//  NetworkTrainDataTimeFrameProvider.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 08.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

import SwiftyJSON

public class NetworkTrainDataTimeFrameProvider: TrainDataProviderProtocol, TrainDataProviderDelegate {
    
    var delegate: TrainDataProviderDelegate? = nil
    let networkService = TransportRestProvider()

    public typealias TripData = TimeFrameTrip
    
    public init() {
        self.networkService.delegate = self
    }
    
    public func getAllTrips() -> Array<TimeFrameTrip> {
        let trips = self.networkService.getAllTrips()
        return HafasParser.loadTimeFrameTrip(fromHafasTrips: trips)
    }
    
    public func update() {
        self.networkService.update()
    }
    
    public func setDeleate(delegate: TrainDataProviderDelegate) {
        self.delegate = delegate
    }
    
    public func onTripsUpdated() {
        self.delegate?.onTripsUpdated()
    }
}
