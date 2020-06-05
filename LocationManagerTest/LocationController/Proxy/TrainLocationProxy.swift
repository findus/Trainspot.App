//
//  TrainLocationProxy.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

class TrainLocationProxy: NSObject {
    
    //var controllers: Array<TrainLocationProtocol> = []
    public var delegate: TrainLocationDelegate?
    
    public static let shared = TrainLocationProxy()
    
    private override init() {
        
    }
    
    func register<T: TrainLocationProtocol>(controller: T) {
        print("Registered \(String(describing: controller.self)) as a TrainLocation Controller")
        var ctrl = controller
        ctrl.delegate = self
        //controllers.append(ctrl)
        controller.update()
        controller.start()
    }
    
    func updateAll() {
        
    }
        
}

extension TrainLocationProxy : TrainLocationDelegate {
    func drawPolyLine(forTrip: Trip) {
        self.delegate?.drawPolyLine(forTrip: forTrip)
    }
    
    func trainPositionUpdated(forTrip trip: Trip, toPosition: CLLocation, withDuration duration: Double) {
        self.delegate?.trainPositionUpdated(forTrip: trip, toPosition: toPosition, withDuration: duration)
    }
}
