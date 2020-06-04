//
//  TrainLocationProtocol.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

protocol TrainLocationProtocol {
    func register(trip :Trip)
    func start()
    func update()
    func setDataProvider<T: TrainDataProviderProtocol>(withProvider provider: T)
    var delegate: TrainLocationDelegate? { set get }
}
