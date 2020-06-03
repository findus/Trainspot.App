//
//  MapViewController.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import UIKit
import CoreLocation

protocol MapViewControllerProtocol: NSObject {
    func addEntry(entry: MapEntity)
    func deleteEntry(entry: MapEntity)
    func updateTrainLocation(forId id: String, toLocation location: CLLocationCoordinate2D, withDuration duration: Double)
}
