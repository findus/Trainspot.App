//
//  TrainLocationPin.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import MapKit

class TrainPin : NSObject, MKAnnotation {
    dynamic var coordinate : CLLocationCoordinate2D

    init(location coord:CLLocationCoordinate2D) {
        self.coordinate = coord
        super.init()
    }
}
