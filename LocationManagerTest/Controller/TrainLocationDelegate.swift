//
//  TrainLocationDelegate.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

protocol TrainLocationDelegate: NSObject {
    func trainPositionUpdated(forJourney journey: Journey, toPosition: Int, withDuration duration: Double) -> Void
}
