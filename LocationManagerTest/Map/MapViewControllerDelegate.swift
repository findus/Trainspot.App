//
//  MapViewControllerDelegate.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import UIKit
import CoreLocation

protocol MapViewControllerDelegate: NSObject {
    func userPressedAt(location: CLLocation)
}
