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
    public func bearingToLocationRadian(_ destinationLocation: CLLocation) -> CGFloat {
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
    
    public func bearingToLocationDegrees(destinationLocation: CLLocation) -> CGFloat {
        return bearingToLocationRadian(destinationLocation).toDegrees
        
    }
    
    public func midPoint(withLocation location: CLLocation) -> CLLocation {
        var c1 = CLLocationCoordinate2D()
        var c2 = CLLocationCoordinate2D()
        
        c2.latitude = self.coordinate.latitude.toRadiansd
        c1.latitude = location.coordinate.latitude.toRadiansd
        
        c2.longitude = self.coordinate.longitude
        c1.longitude = location.coordinate.longitude

        let dLon = (c2.longitude - c1.longitude).toRadiansd
        let bx = cos(c2.latitude) * cos(dLon);
        let by = cos(c2.latitude) * sin(dLon);
        let latitude = atan2(sin(c1.latitude) + sin(c2.latitude), sqrt((cos(c1.latitude) + bx) * (cos(c1.latitude) + bx) + by*by));
        let longitude = c1.longitude.toRadiansd + atan2(by, cos(c1.latitude) + bx);

        var midpointCoordinate = CLLocationCoordinate2D()
        midpointCoordinate.longitude = longitude.toDegreesd
        midpointCoordinate.latitude = latitude.toDegreesd

        return CLLocation(latitude: midpointCoordinate.latitude, longitude: midpointCoordinate.longitude);

    }
}
