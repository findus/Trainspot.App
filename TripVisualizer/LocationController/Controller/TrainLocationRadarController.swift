//
//  TrainLocationController.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

/**
 Gets Trips from the Hafas Radar Endpoints and prints them on the map, only availlable for DB Fernverkehr
 Pretty old and needs further refactoring to make it usable again
 */
public class TrainLocationRadarController: TrainLocationProtocol, Updateable {

    public typealias T = RadarTrip
    public typealias P = TripProvider<T>
    
    var trips: Set<T> = Set.init()
    var timer: Timer? = nil
    public var uid: UUID
    private var dataProvider: P?

    weak public var delegate: TrainLocationDelegate?
        
    public init() {
        self.uid = UUID()
    }
    
    
    public func register(trip: T) {
        self.trips.insert(trip)
        let data = TripData(location: trip.polyline[0].location, state: .Driving(nil), arrival: -1, delay: 0)
        self.delegate?.trainPositionUpdated(forTrip: trip, withData: data, withDuration: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.updateTrip(trip: trip)
        }
    }
    
    @objc private func eventLoop() {
        Log.trace("Event loop")
        self.trips.forEach { (trip) in
            self.updateTrip(trip: trip)
        }
    }
    
    public func refreshSelected(trips: Array<T>) {
        fatalError("Unimplemented")
    }
    
    private func updateTrip(trip: Trip) {
        guard let arrayPosition = trip.currentTrainPosition() else {
            return
        }
        let tripData = TripData(location: trip.polyline[arrayPosition].location, state: .Driving(nil), arrival: -1, delay: 0)
        self.delegate?.trainPositionUpdated(forTrip: trip, withData: tripData, withDuration: DURATION)
    }
    
    public func setCurrentLocation(location: CLLocation) {
        fatalError("Not yet implemented")
    }
    
    public func remove(trip: RadarTrip) {
        
    }
    
    public func start() {
        self.timer = Timer.scheduledTimer(timeInterval: DURATION, target: self, selector: #selector(eventLoop), userInfo: nil, repeats: true)
    }
    
    public func pause() {
        self.timer?.invalidate()
        //TODO recalc animations
        fatalError("Pausing not fully implemented")
    }
    
    public func update() {
        guard let trips = dataProvider?.getAllTrips() else {
            return
        }
        self.trips = trips
    }
    
    public func getTrip(withID id: String) -> T? {
        fatalError("Not implemented")
    }
    
    public func setDataProvider(withProvider provider: TripProvider<RadarTrip>) {
        self.dataProvider = provider
    }
    
    public func onNewClientRegistered(_ client: TrainLocationDelegate) {
        fatalError("Not yet implemented")
    }
    
}
