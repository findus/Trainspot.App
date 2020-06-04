//
//  TrainLocationController.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

class TrainLocationController {
        
    var journeys: Array<Journey> = [Journey]()
    var timer: Timer? = nil


    static let shared = TrainLocationController()
    
    weak var delegate: TrainLocationDelegate?
        
    private init() {
        self.timer = Timer.scheduledTimer(timeInterval: DURATION, target: self, selector: #selector(eventLoop), userInfo: nil, repeats: true)
    }
    
    func register(journey: Journey) {
        self.journeys.append(journey)
        self.delegate?.trainPositionUpdated(forJourney: journey, toPosition: 0, withDuration: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.updateJourney(journey: journey)
        }
    }
    
    @objc private func eventLoop() {
        print("Event loop")
        self.journeys.forEach { (journey) in
            self.updateJourney(journey: journey)
        }
    }
    
    private func updateJourney(journey: Journey) {
        guard let arrayPosition = journey.currentTrainPosition(forJourney: journey) else {
            return
        }
        self.delegate?.trainPositionUpdated(forJourney: journey, toPosition: arrayPosition, withDuration: DURATION)
    }
}
