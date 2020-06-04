//
//  TrainLocationProxy.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

class TrainLocationProxy: NSObject {
    
    var controllers: Array<TrainLocationProtocol> = []
    public var delegate: TrainLocationDelegate?
    
    public static let shared = TrainLocationProxy()
    
    private override init() {
        
    }
    
    func register<T: TrainLocationProtocol>(controller: T) {
        var ctrl = controller
        ctrl.delegate = self
        controllers.append(ctrl)
    }
    
    func updateAll() {
        
    }
        
}

extension TrainLocationProxy : TrainLocationDelegate {
    func trainPositionUpdated(forTrip trip: Trip, toPosition: Int, withDuration duration: Double) {
        self.delegate?.trainPositionUpdated(forTrip: trip, toPosition: toPosition, withDuration: duration)
    }
}
