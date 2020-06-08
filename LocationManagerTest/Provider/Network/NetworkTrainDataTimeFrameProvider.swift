//
//  NetworkTrainDataTimeFrameProvider.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 08.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

import SwiftyJSON

class NetworkTrainDataTimeFrameProvider: TrainDataProviderProtocol, TrainDataProviderDelegate {
    
    var delegate: TrainDataProviderDelegate? = nil
    let networkService = TransportRestProvider()

    typealias TripData = TimeFrameTrip
    
    init() {
        self.networkService.delegate = self
    }
    
    func getAllTrips() -> Array<TimeFrameTrip> {
        let trips = self.networkService.getAllTrips()
        return HafasParser.loadTimeFrameTrip(fromHafasTrips: trips)
    }
    
    func update() {
        self.networkService.update()
    }
    
    func setDeleate(delegate: TrainDataProviderDelegate) {
        self.delegate = delegate
    }
    
    func onTripsUpdated() {
        self.delegate?.onTripsUpdated()
    }
}
