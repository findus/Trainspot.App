//
//  TripHandler.swift
//  Trainspot.App
//
//  Created by Philipp Hentschel on 15.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import TripVisualizer
import CoreLocation

//TODO proxy holder for controller
public class TripHandler {
    
    private let manager = TrainLocationProxy.shared
    public static let shared = TripHandler()
    private var tripTimeFrameLocationController = TrainLocationTripByTimeFrameController()
    public var demoTimer: TimeTraveler?
    
    private init() {
        #if MOCK
        self.setupDemo()
        #else
        tripTimeFrameLocationController.setDataProvider(withProvider: TripProvider(NetworkTrainDataTimeFrameProvider()))
        #endif
        
        self.manager.register(controller: tripTimeFrameLocationController)
    }
    
    func setupDemo() {
        var components = DateComponents()
        components.second = 0
        components.hour = 17
        components.minute = 19
        components.day = 18
        components.month = 9
        components.year = 2020
        let date = Calendar.current.date(from: components)
        let traveler = TimeTraveler()
        self.demoTimer = traveler
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            traveler.travel(by: 60)
        }
        traveler.date = date!
        self.tripTimeFrameLocationController.pause()

        tripTimeFrameLocationController.setDataProvider(withProvider: TripProvider(MockTrainDataTimeFrameProvider(withFile: "ice_huge_delay")))
        tripTimeFrameLocationController.dateGenerator = traveler.generateDate
        
        // Hildesheim
        let loc = CLLocation(latitude: 52.161407, longitude: 9.938503)
        tripTimeFrameLocationController.setCurrentLocation(location: loc)
        UserLocationController.shared.deactivate()
        UserPrefs.setManualLocationEnabled(true)
        UserPrefs.setHasUserActivatedManualLocation(true)
        UserPrefs.setManualLocation(loc)
        UserPrefs.setSelectedStation(StationInfo("Braunschweig Hbf", "8000049"))
    }
    
    func start() {
        self.triggerUpdate()
    }
    
    func stop() {
        self.tripTimeFrameLocationController.pause()
    }
    
    func forceStart() {
        self.tripTimeFrameLocationController.fetchServer()
    }
    
    func triggerUpdate() {
        if UserPrefs.getfirstOnboardingTriggered() == true {
            self.tripTimeFrameLocationController.fetchServer()
        }
    }
    
    func setCurrentLocation(_ location: CLLocation) {
        self.tripTimeFrameLocationController.setCurrentLocation(location: location)
    }
        
}
