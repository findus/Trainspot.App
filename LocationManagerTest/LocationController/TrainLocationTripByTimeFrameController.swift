//
//  TrainLocationTripByTimeFrameController.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation
import Log

/**
 This class controls trips, that have no direct binding from locations and times, for example if you download a timetable
 This Controller tries to calculate proper animations for a trip
 */
class TrainLocationTripByTimeFrameController: TrainLocationProtocol  {
    
    typealias T = TimeFrameTrip
    typealias P = TripProvider<T>

    weak var delegate: TrainLocationDelegate?
        
    var trips: [String: (TimeFrameTrip, Timer)] = [:]
    private var timer: Timer? = nil
    private var dataProvider: TripProvider<T>?
    
    var timers : Array<Timer> = []
    
    var datestack : Array<Date> = []
    
    init() {
        var dateComponents = DateComponents()
        dateComponents.year = 2020
        dateComponents.month = 6
        dateComponents.day = 4
        dateComponents.hour = 15
        dateComponents.minute = 2
        dateComponents.second = 55
        
        // Create date from components
        let userCalendar = Calendar.current // user calendar
        datestack.append(userCalendar.date(from: dateComponents)!)
        
        dateComponents.minute = 0
        dateComponents.second = 0
        
        datestack.append(userCalendar.date(from: dateComponents)!)
    }
    
    func start() {
        self.trips.values.forEach { (trip, timer) in
            self.startTrip(trip: trip, withDate: datestack.popLast()!)
        }
    }
    
    private func startTrip(trip: TimeFrameTrip, withDate date: Date = Date()) {
        // TODO somehow handle not startet trips
        
        
    }

    private func startNewAnimation(forTrip trip: TimeFrameTrip, toPosition position: CLLocation, withDuration duration: TimeInterval, andArrayPosition pos: Int) {
        Log.debug("New Animation for: ", trip.name, "Duration: ", duration, "Seconds")
        self.trips[trip.name]?.1.invalidate()
        self.delegate?.trainPositionUpdated(forTrip: trip, toPosition: position, withDuration: duration)
        self.trips[trip.name] = (trip ,Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(expired), userInfo: (trip.name, pos), repeats: true))
    }
    
    func update() {
        guard let trips = dataProvider?.getAllTrips() else {
            print("Error retreiving trips")
            return
        }
        
        trips.forEach { self.register(trip: $0); self.delegate?.drawPolyLine(forTrip: $0) }
    }
    
    func register(trip: T) {
        self.trips[trip.name] = (trip, Timer())
    }
    
    
    @objc private func expired(timer: Timer) {
        let (name, pos) = timer.userInfo as! (String,Int)
        self.updateTrip(trip: self.trips[name]!.0 , arrayPosition: pos)
    }
    
    private func updateTrip(trip: TimeFrameTrip, arrayPosition: Int) {

    }
    
    func setDataProvider(withProvider provider: TripProvider<TimeFrameTrip>) {
        self.dataProvider = provider
    }

}

//MARK: -- Location Tracking
