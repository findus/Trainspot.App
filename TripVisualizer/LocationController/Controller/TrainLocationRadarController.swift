//
//  TrainLocationController.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

class TrainLocationRadarController: TrainLocationProtocol {

    typealias T = RadarTrip
    typealias P = TripProvider<T>
    
    var trips: Array<T> = [T]()
    var timer: Timer? = nil
    private var dataProvider: TripProvider<T>?

    weak var delegate: TrainLocationDelegate?
        
    init() {
        
    }
    
    
    func register(trip: T) {
        self.trips.append(trip)
        let data = TripData(location: trip.polyline[0].location, state: .Driving(nil), arrival: -1)
        self.delegate?.trainPositionUpdated(forTrip: trip, withData: data, withDuration: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.updateTrip(trip: trip)
        }
    }
    
    @objc private func eventLoop() {
        print("Event loop")
        self.trips.forEach { (trip) in
            self.updateTrip(trip: trip)
        }
    }
    
    private func updateTrip(trip: Trip) {
        guard let arrayPosition = trip.currentTrainPosition() else {
            return
        }
        let tripData = TripData(location: trip.polyline[arrayPosition].location, state: .Driving(nil), arrival: -1)
        self.delegate?.trainPositionUpdated(forTrip: trip, withData: tripData, withDuration: DURATION)
    }
    
    func setCurrentLocation(location: CLLocation) {
        fatalError("Not yet implemented")
    }
    
    func remove(trip: RadarTrip) {
        
    }
    
    func start() {
        self.timer = Timer.scheduledTimer(timeInterval: DURATION, target: self, selector: #selector(eventLoop), userInfo: nil, repeats: true)
    }
    
    func pause() {
        self.timer?.invalidate()
        //TODO recalc animations
        fatalError("Pausing not fully implemented")
    }
    
    func update() {
        guard let trips = dataProvider?.getAllTrips() else {
            return
        }
        self.trips = trips
    }
    
    func setDataProvider(withProvider provider: TripProvider<RadarTrip>) {
        self.dataProvider = provider
    }
    
    
}
