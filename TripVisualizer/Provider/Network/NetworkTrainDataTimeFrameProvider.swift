//
//  NetworkTrainDataTimeFrameProvider.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 08.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation


public class NetworkTrainDataTimeFrameProvider: TrainDataProviderProtocol, TrainDataProviderDelegate {

    var delegate: TrainDataProviderDelegate? = nil
    let networkService = TransportRestProvider<TimeFrameTrip>()

    public typealias TripData = TimeFrameTrip
    public typealias PassedTrips = TimeFrameTrip
    
    public init() {
        self.networkService.delegate = self
    }
    
    public func getAllTrips() -> Set<TimeFrameTrip> {
        let trips = self.networkService.getAllTrips()
        return HafasParser.loadTimeFrameTrip(fromHafasTrips: trips)
    }
    
    public func update() {
        self.networkService.update()
    }
    
    public func setDeleate(delegate: TrainDataProviderDelegate) {
        self.delegate = delegate
    }
    
    public func onTripsUpdated(result: Result) {
        self.delegate?.onTripsUpdated(result: result)
    }
    
    public func onTripSelectionRefreshed(result: Result) {
        self.delegate?.onTripSelectionRefreshed(result: result)
    }
    
    public func updateExistingTrips(_ trips: Array<TimeFrameTrip>) {
        self.networkService.updateSelectedTrips(trips: trips)
    }
      
}
