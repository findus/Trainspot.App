//
//  TrainLocationController.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

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
        self.delegate?.trainPositionUpdated(forTrip: trip, toPosition: trip.polyline[0].location, withDuration: 0)
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
        self.delegate?.trainPositionUpdated(forTrip: trip, toPosition: trip.polyline[arrayPosition].location, withDuration: DURATION)
    }
    
    func remove(trip: RadarTrip) {
        
    }
    
    func start() {
        self.timer = Timer.scheduledTimer(timeInterval: DURATION, target: self, selector: #selector(eventLoop), userInfo: nil, repeats: true)
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
