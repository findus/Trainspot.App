//
//  TrainLocationTripController.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

class TrainLocationTripController: TrainLocationProtocol  {

    typealias T = JourneyTrip
    typealias P = TripProvider<T>

    weak var delegate: TrainLocationDelegate?
        
    var trips: Array<JourneyTrip> = [JourneyTrip]()
    private var timer: Timer? = nil
    private var dataProvider: TripProvider<T>?
            
    init() {
        // self.dataProvider = MockTrainDataJourneyProvider()
    }
    
    func start() {
        self.timer = Timer.scheduledTimer(timeInterval: 100, target: self, selector: #selector(eventLoop), userInfo: nil, repeats: true)
    }
    
    func update() {
        guard let trips = dataProvider?.getAllTrips() else {
            print("Error retreiving trips")
            return
        }
        
        trips.forEach { self.register(trip: $0); self.delegate?.drawPolyLine(forTrip: $0) }
    }
    
    func register(trip: T) {
        self.trips.append(trip)
        self.delegate?.trainPositionUpdated(forTrip: trip, toPosition: trip.line[0].location, withDuration: 0)
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
    
    private func updateTrip(trip: JourneyTrip) {
        guard let arrayPosition = trip.currentTrainPosition() else {
            return
        }
        self.delegate?.trainPositionUpdated(forTrip: trip, toPosition: trip.line[0].location, withDuration: 1)
    }
    
    func setDataProvider(withProvider provider: TripProvider<JourneyTrip>) {
        self.dataProvider = provider
    }

}
