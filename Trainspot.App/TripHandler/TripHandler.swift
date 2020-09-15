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
    
    private init() {
        #if MOCK
               var components = DateComponents()
               components.second = 0
               components.hour = 0
               components.minute = 0
               components.day = 14
               components.month = 9
               components.year = 2020
               let date = Calendar.current.date(from: components)
               let traveler = TimeTraveler()
               Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
                   traveler.travel(by: 1)
               }
               traveler.date = date!
               tripTimeFrameLocationController = TrainLocationTripByTimeFrameController(dateGenerator: traveler.generateDate)
               tripTimeFrameLocationController.setDataProvider(withProvider: TripProvider(MockTrainDataTimeFrameProvider(withFile: "bs_delay")))
               #else
               tripTimeFrameLocationController.setDataProvider(withProvider: TripProvider(NetworkTrainDataTimeFrameProvider()))
               #endif
               
               self.manager.register(controller: tripTimeFrameLocationController)
    }
    
    func startDemo() {
        
    }
    
    func startNormalMode() {
        self.triggerUpdate()
    }
    
    func stop() {
        self.tripTimeFrameLocationController.pause()
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
