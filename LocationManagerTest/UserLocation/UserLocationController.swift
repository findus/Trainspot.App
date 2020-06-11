//
//  UserLocationController.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 11.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

class UserLocationController: NSObject, CLLocationManagerDelegate {
    
    private var delegates: Array<CLLocationManagerDelegate> = Array.init()
   
    public static let shared = UserLocationController()
    
    let locationManager = CLLocationManager()

    private override init() {
        super.init()
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
    }
    
    func register(delegate: CLLocationManagerDelegate) {
        self.delegates.append(delegate)
    }
    
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

}
