//
//  CLLocation+Extension.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import UIKit
import CoreLocation

extension CLLocation {
    func bearingToLocationRadian(_ destinationLocation: CLLocation) -> CGFloat {
        let lat1 = self.coordinate.latitude.toRadians
        let lon1 = self.coordinate.longitude.toRadians
        
        let lat2 = destinationLocation.coordinate.latitude.toRadians
        let lon2 = destinationLocation.coordinate.longitude.toRadians
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y,x)
        
        return CGFloat(radiansBearing)
    }
    
    func bearingToLocationDegrees(destinationLocation: CLLocation) -> CGFloat {
        return bearingToLocationRadian(destinationLocation).toDegrees
        
    }
}
