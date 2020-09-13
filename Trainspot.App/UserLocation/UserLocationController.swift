//
//  UserLocationController.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 11.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftEventBus
import Log
import TripVisualizer

class UserLocationController: NSObject, CLLocationManagerDelegate {
    
    private var delegates: Array<CLLocationManagerDelegate> = Array.init()
   
    public static let shared = UserLocationController()
    
    let locationManager = CLLocationManager()

    private override init() {
        super.init()
       
        self.setupBus()
        
        locationManager.delegate = self
       
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
    }
    
    func deactivate() {
        Log.info("Disabling Location tracking")
        UserPrefs.setManualPositionDetermination(true)
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()

    }
    
    func activate() {
        Log.info("Activating Location tracking")
        UserPrefs.setManualPositionDetermination(false)
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()

    }
    
    func register(delegate: CLLocationManagerDelegate) {
        self.delegates.append(delegate)
    }
    
    func reask() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func isEnabled() -> Bool {
        UserPrefs.getManualPositionDetermination() && CLLocationManager.authorizationStatus() == .authorizedWhenInUse
    }
    
    //MARK: - Delegate methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.delegates.forEach { (delegate) in
            delegate.locationManager?(manager, didUpdateHeading: newHeading)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.delegates.forEach { (delegate) in
            delegate.locationManager?(manager, didUpdateLocations: locations)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (status == .authorizedWhenInUse || status == .authorizedAlways) && UserPrefs.getManualPositionDetermination() == false {
            self.activate()
        } else {
            self.deactivate()
        }
    }

}


// MARK: - Eventbus logic

extension UserLocationController {
    
    private func setupBus() {
        SwiftEventBus.onMainThread(self, name: "useManualPosition") { (notification) in
           
            guard let enabled = notification?.object as? Bool else {
                return
            }
            
            if enabled {
                self.deactivate()
            } else {
                self.activate()
            }
        }
        
    }
    
}
