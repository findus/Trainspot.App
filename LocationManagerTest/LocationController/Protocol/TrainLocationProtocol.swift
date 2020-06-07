//
//  TrainLocationProtocol.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

protocol TrainLocationProtocol {
    associatedtype T : Trip
    associatedtype P
    func remove(trip :T)
    func register(trip :T)
    func start()
    func update()
    func pause()
    func setDataProvider(withProvider provider: P)
    var delegate: TrainLocationDelegate? { set get }
}
