//
//  TrainLocationProtocol.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

public protocol TrainLocationProtocol {
    associatedtype T : Trip
    associatedtype P
    var uid: UUID { get }
    func remove(trip :T)
    func register(trip :T)
    func start()
    func update()
    func pause()
    func setDataProvider(withProvider provider: P)
    func setCurrentLocation(location: CLLocation)
    var delegate: TrainLocationDelegate? { set get }
}
