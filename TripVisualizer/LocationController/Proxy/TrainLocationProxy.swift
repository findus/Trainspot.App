//
//  TrainLocationProxy.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

public class TrainLocationProxy: NSObject {
    
    public var delegate: Array<TrainLocationDelegate>? = Array.init()
    
    public static let shared = TrainLocationProxy()
    
    private override init() {
        
    }
    
    public func register<T: TrainLocationProtocol>(controller: T) {
        print("Registered \(String(describing: controller.self)) as a TrainLocation Controller")
        var ctrl = controller
        ctrl.delegate = self
        //controllers.append(ctrl)
        controller.update()
        controller.start()
    }
    
    public func updateAll() {
        
    }
    
    public func addListener(listener: TrainLocationDelegate) {
        Log.debug("Added Listener \(listener.id) to Proxy")
        self.delegate?.append(listener)
    }
    
    public func removeLitener(listener: TrainLocationDelegate) {
        Log.debug("Removed Listener \(listener.id) to Proxy")
        self.delegate?.removeAll(where: { $0.id == listener.id } )
    }
        
}

extension TrainLocationProxy : TrainLocationDelegate {
   
    public var id: String {
        return "LocationProxy"
    }
    
    public func removeTripFromMap(forTrip trip: Trip) {
        self.delegate?.forEach( { delegate in delegate.removeTripFromMap(forTrip: trip) })
    }
    
    public func drawPolyLine(forTrip: Trip) {
        self.delegate?.forEach( { delegate in delegate.drawPolyLine(forTrip: forTrip) })
    }
    
    public func trainPositionUpdated(forTrip trip: Trip, withData data: TripData, withDuration duration: Double) {
        self.delegate?.forEach( { delegate in delegate.trainPositionUpdated(forTrip: trip, withData: data, withDuration: duration) })
    }
    
    public func onUpdateStarted() {
        self.delegate?.forEach( { delegate in delegate.onUpdateStarted() })
    }
    
    public func onUpdateEnded() {
        self.delegate?.forEach( { delegate in delegate.onUpdateEnded()})
    }
}
