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
    public var delegate: Array<TrainLocationDelegate>?
    
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
    
    func addListener(listener: TrainLocationDelegate) {
        Log.debug("Added Listener \(listener.id) to Proxy")
        self.delegate?.append(listener)
    }
    
    func removeLitener(listener: TrainLocationDelegate) {
        Log.debug("Removed Listener \(listener.id) to Proxy")
        self.delegate?.removeAll(where: { $0.id == listener.id } )
    }
        
}

extension TrainLocationProxy : TrainLocationDelegate {
    var id: String {
        return "LocationProxy"
    }
    
    func removeTripFromMap(forTrip trip: Trip) {
        self.delegate?.forEach( { _ in removeTripFromMap(forTrip: trip) })
    }
    
    func drawPolyLine(forTrip: Trip) {
        self.delegate?.forEach( { _ in drawPolyLine(forTrip: forTrip) })
    }
    
    func trainPositionUpdated(forTrip trip: Trip, toPosition: CLLocation, withDuration duration: Double) {
        self.delegate?.forEach( { _ in trainPositionUpdated(forTrip: trip, toPosition: toPosition, withDuration: duration) })
    }
}
