//
//  TrainLocationController.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

class TrainLocationController {
        
    var duration = 45.0
    var journeys: Array<Journey> = [Journey]()
    var timer: Timer? = nil
    static let T_45_MINUTES  = 2700.0
    
    static let shared = TrainLocationController()
    
    weak var delegate: TrainLocationDelegate?
        
    private init() {
        self.timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(eventLoop), userInfo: nil, repeats: true)
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
        guard let arrayPosition = self.calculateTrainPosition(forJourney: journey) else {
            return
        }
        self.delegate?.trainPositionUpdated(forJourney: journey, toPosition: arrayPosition, withDuration: duration)
    }
    
    /**
     Returns the current position of the train, which is the nth position inside the array, returns empty if array bounds are exceeded
     */
    private func calculateTrainPosition(forJourney journey: Journey) -> Int? {
        let date = journey.fetchTime
        let now = Date.init()
        let diff = now.timeIntervalSince(date)
        if diff > TrainLocationController.T_45_MINUTES {
            print("Journey \(journey.name) exceeded max time")
            return nil
        } else {
            let arrayPosition = Int(floor( ( (1 / 45) * ceil(diff) ) )  + 1)
            print("Returning \(arrayPosition) for \(journey.name)")
            return arrayPosition
        }
    }
    
}
