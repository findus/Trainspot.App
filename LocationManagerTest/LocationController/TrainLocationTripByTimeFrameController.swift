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
    
    var i : Double = 0
    
    init() {
        var dateComponents = DateComponents()
        dateComponents.year = 2020
        dateComponents.month = 6
        dateComponents.day = 4
        dateComponents.hour = 15
        dateComponents.minute = 4
        dateComponents.second = 00
        
        // Create date from components
        let userCalendar = Calendar.current // user calendar
        datestack.append(userCalendar.date(from: dateComponents)!)
        
        dateComponents.minute = 0
        dateComponents.second = 40
        
        datestack.append(userCalendar.date(from: dateComponents)!)
    }
    
    func start() {
        self.trips.values.forEach { (trip, timer) in
            self.startTrip(trip: trip, withDate: datestack.popLast()!)
        }
    }
    
    private func startTrip(trip: TimeFrameTrip, withDate date: Date = Date()) {
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(test), userInfo: (trip, date), repeats: true)
    }
    
    @objc func test(timer: Timer) {
        var (trip, date) = timer.userInfo as! (TimeFrameTrip, Date)
        let coord = self.getTrainLocation(forTrip: trip, atDate: date.addingTimeInterval(i))
        i += 1
        print( date.addingTimeInterval(i))
        self.delegate?.trainPositionUpdated(forTrip: trip, toPosition: coord, withDuration: 0)
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
    
    func setDataProvider(withProvider provider: TripProvider<TimeFrameTrip>) {
        self.dataProvider = provider
    }

}

//MARK: -- Location Tracking

extension TrainLocationTripByTimeFrameController {
    func getTrainLocation(forTrip trip: TimeFrameTrip, atDate date: Date) -> CLLocation {
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
                fatalError()
        }
        
        
        let location = loc.0
        
        // Check if currently stopping
        
        if location is StopOver {
            let stopover = (location as! StopOver)
            if stopover.arrival?.timeIntervalSince(date) ?? 1 <= 0 && stopover.departure!.timeIntervalSince(date) > 0 {
                Log.debug("Currently halting til \(stopover.departure!) [\(stopover.departure!.timeIntervalSince(date)) seconds]")
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
