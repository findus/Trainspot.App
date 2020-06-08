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
        
    var trips: Set<TimeFrameTrip> = Set.init()
    private var timer: Timer? {
        didSet {
            oldValue?.invalidate()
        }
    }
    private var dataProvider: TripProvider<T>?
        
    var datestack : Array<Date> = []
    
    var i : Double = 0
    
    init() {
        var dateComponents = DateComponents()
        dateComponents.year = 2020
        dateComponents.month = 6
        dateComponents.day = 4
        dateComponents.hour = 14
        dateComponents.minute = 54
        dateComponents.second = 00
        
        // Create date from components
        let userCalendar = Calendar.current // user calendar
        datestack.append(userCalendar.date(from: dateComponents)!)
        
        dateComponents.minute = 54
        dateComponents.second = 10
        
        datestack.append(userCalendar.date(from: dateComponents)!)
    }
    
    func remove(trip: TimeFrameTrip) {
        self.timer?.invalidate()
        self.trips.remove(trip)
        self.delegate?.removeTripFromMap(forTrip: trip)
        self.start()
    }
    
    func start() {
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(onTick), userInfo: nil, repeats: true)
    }
    
    func pause() {
        self.timer?.invalidate()
    }
    
    @objc func onTick(timer: Timer) {
        self.trips.forEach { (trip) in
            if isTripInBounds(trip: trip) {
                if let coord = self.getTrainLocation(forTrip: trip, atDate: Date()) {
                    self.delegate?.trainPositionUpdated(forTrip: trip, toPosition: coord, withDuration: 1)
                }
            } else {
                Log.info("Gonna remove Trip \(trip) from set, because time is invalid")
                self.remove(trip: trip)
            }
        }
    }
    
    func fetchServer() {
        self.dataProvider?.update()
    }

    func update() {
        
        //Stop timer while updating entries
        self.timer?.invalidate()
        
        guard let trips = dataProvider?.getAllTrips() else {
            print("Error retreiving trips")
            return
        }
        
        let set = Set(trips)
        
        let remaining = self.trips.intersection(set)
        let new = set.subtracting(self.trips)
        let lost = self.trips.subtracting(remaining)
        
        lost.forEach { (poorLostTrip) in
            Log.info("Lost Trip \(poorLostTrip.name)")
            self.delegate?.removeTripFromMap(forTrip: poorLostTrip)
        }
        
        new.forEach { (newTrips) in
            Log.info("Got new Trip \(newTrips.name)")
        }
        
        self.trips = remaining.union(new)
        
        self.start()
    }
    
    func register(trip: T) {
        self.trips.insert(trip)
    }
    
    func setDataProvider(withProvider provider: TripProvider<TimeFrameTrip>) {
        self.dataProvider = provider
        self.dataProvider?.setDeleate(delegate: self)
    }

}

//Mark: -- Update Handling

extension TrainLocationTripByTimeFrameController: TrainDataProviderDelegate {
    func onTripsUpdated() {
        Log.info("Trips got updated")
        self.update()
    }
}

//MARK: -- Location Tracking

extension TrainLocationTripByTimeFrameController {
    
    private func isTripInBounds(trip: TimeFrameTrip) -> Bool {
        let start = trip.departure
        let end = trip.locationArray.last?.departure ?? Date.init(timeIntervalSince1970: 0)
        let now = Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.mm.yyyy HH:mm"
        
        if start.timeIntervalSince(now) >= 0 || end.timeIntervalSince(now) <= 0 {
            Log.warning("Trip \(trip.name) is not in bounds!")
            if start.timeIntervalSince(now) >= 0 {
                Log.warning("[\(formatter.string(from: trip.departure))....[\(formatter.string(from: end))]..................\(formatter.string(from: start))")
            } else {
                Log.warning("\(formatter.string(from: start))..................[\(formatter.string(from: trip.departure)).....\(formatter.string(from: end))]")
            }
            return false
        }
        return true
    }
    
    func getTrainLocation(forTrip trip: TimeFrameTrip, atDate date: Date) -> CLLocation? {
        guard let loc = zip(trip.locationArray,trip.locationArray.dropFirst())
            .first(where: { (this, next) -> Bool in
                if this is Path && next is StopOver {
                    /**
                     Map Against Arrival Data:
                    Section Start       Train     Arrival       Departure
                        |__________*_____|     Stop     |________> Time .
                      15:00              15:02    15:03          15:04
                     */
                return (this as! Path).departure!.timeIntervalSince(date) <= 0 && (next as! StopOver).arrival!.timeIntervalSince(date) > 0
               
                } else if this is StopOver && next is Path {
                    /**
                    Map Against Arrival Data:
                    Section Start                     Arrival       Departure
                        |________________|     Train     |________> Time .
                    15:00                                 15:03          15:04
                    */
                   return
                            ((this as! StopOver).arrival?.timeIntervalSince(date) ?? 1 <= 0 && (this as! StopOver).departure!.timeIntervalSince(date) > 0)
                        ||
                                (this as! StopOver).departure!.timeIntervalSince(date) <= 0 && (next).departure!.timeIntervalSince(date) >= 0

                } else {
                    return this.departure!.timeIntervalSince(date) <= 0 && next.departure!.timeIntervalSince(date) > 0
                }
            }) else {
                Log.error("Error finding a location for Trip \(trip.name) at \(date)")
                return nil
        }
        
        
        let location = loc.0
        
        // Check if currently stopping
        
        if location is StopOver {
            let stopover = (location as! StopOver)
            if stopover.arrival?.timeIntervalSince(date) ?? 1 <= 0 && stopover.departure!.timeIntervalSince(date) > 0 {
                Log.debug("[\(trip.name)] Currently halting at: \(stopover.name) til \(stopover.departure!) [\(stopover.departure!.timeIntervalSince(date)) seconds]")
                return stopover.coords
            }
        }
        
        let wholeDuration = location.durationToNext!
        let departure = location.departure!
       
        let startCoords = location.coords.coordinate
        let endCoords = loc.1.coords.coordinate
        
        let secondsIntoSection = ( date.timeIntervalSince(departure) )
        
        let ratio = secondsIntoSection / wholeDuration
        
        let newLat = startCoords.latitude + ((endCoords.latitude - startCoords.latitude) * ratio)
        let newLon = startCoords.longitude + ((endCoords.longitude - startCoords.longitude) * ratio)
        
        return CLLocation(latitude: newLat, longitude: newLon)
    }
}
