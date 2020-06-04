//
//  TrainLocationController.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

class TrainLocationRadarController: TrainLocationProtocol {
        
    var trips: Array<Trip> = [Trip]()
    var timer: Timer? = nil
    
    weak var delegate: TrainLocationDelegate?
        
    init() {
        self.timer = Timer.scheduledTimer(timeInterval: DURATION, target: self, selector: #selector(eventLoop), userInfo: nil, repeats: true)
    }
    
    func register(trip: Trip) {
        self.trips.append(trip)
        self.delegate?.trainPositionUpdated(forTrip: trip, toPosition: 0, withDuration: 0)
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
        guard let arrayPosition = trip.currentTrainPosition(forTrip: trip) else {
            return
        }
        self.delegate?.trainPositionUpdated(forTrip: trip, toPosition: arrayPosition, withDuration: DURATION)
    }
}
