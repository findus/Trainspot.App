//
//  MapViewController.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import UIKit

protocol MapViewControllerProtocol: NSObject {
    func addEntry(entry: MapEntity)
    func updateEntry(entry: MapEntity)
    func deleteEntry(entry: MapEntity)
}
