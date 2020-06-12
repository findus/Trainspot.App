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
    
    private var currentUserLocation: CLLocation?
        
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
    
    func remove(trip: TimeFrameTrip, reason: TrainState) {
        let data = TripData(location: nil, state: reason, nextStop: nil, arrival: -1)
        self.delegate?.trainPositionUpdated(forTrip: trip, withData: data, withDuration: 1)
        self.remove(trip: trip)
    }
    
    func start() {
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(onTick), userInfo: nil, repeats: true)
    }
    
    func pause() {
        self.timer?.invalidate()
    }
    
    func getArrivalInSeconds(forTrip trip: T, userPos: CLLocation, trainPos: Int) -> TimeInterval? {
        //Currently only on top of polyline point, might be off if user is between points that ar far away
        let arr = trip.shortestDistanceArrayPosition(forUserLocation: userPos)

        /**
         Tries to get the next stop facing from the users position, fetches the time of next arrivals and substracts the time that is needed to get there
         */
        guard let nextStop = trip.locationArray[arr...].enumerated().first(where: { $0.element is StopOver && ($0.element as? StopOver)?.arrival != nil }) else {
            return nil
        }

        let a = (nextStop.element as! StopOver).arrival!
        let offset = trip.locationArray[arr...(arr+nextStop.offset)].map({$0.durationToNext!}).reduce(0,+)
        return a.addingTimeInterval(-offset).timeIntervalSince(Date())
    }
    
    func setCurrentLocation(location: CLLocation) {
        self.currentUserLocation = location
    }
    
    @objc func onTick(timer: Timer) {
        self.trips.forEach { (trip) in
            switch self.isTripInBounds(trip: trip) {
            case .Driving, .Stopped(_):
                if let data = self.getTrainLocation(forTrip: trip, atDate: Date()) {
                    
                    var tripData: TripData
                    if let currentLocation = self.currentUserLocation {
                        let time = self.getArrivalInSeconds(forTrip: trip, userPos: currentLocation, trainPos: data.2)
                        tripData = TripData(location: data.0, state: data.1, nextStop: "hell", arrival: time ?? -1 )
                    } else {
                        tripData = TripData(location: data.0, state: data.1, nextStop: "hell", arrival: -1)
                    }
                    self.delegate?.trainPositionUpdated(forTrip: trip, withData: tripData, withDuration: 1)
                } else {
                    Log.info("Gonna remove Trip \(trip) from set, because time is invalid")
                    self.remove(trip: trip, reason: .Ended)
                }
            case .Ended:
                self.remove(trip: trip, reason: .Ended)
            case .WaitForStart:
                self.remove(trip: trip, reason: .WaitForStart)
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
        
        trips.forEach { self.delegate?.drawPolyLine(forTrip: $0) }
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
    
    private func isTripInBounds(trip: TimeFrameTrip) -> TrainState {
        let start = trip.departure.addingTimeInterval(-2700)
        let end = (trip.locationArray.last! as! StopOver).arrival ?? Date.init(timeIntervalSince1970: 0)
        let now = Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.mm.yyyy HH:mm"
        
        if start.timeIntervalSince(now) >= 0 || end.timeIntervalSince(now) <= 0 {
            if start.timeIntervalSince(now) >= 0 {
                Log.warning("Trip \(trip.name) is in future")
                Log.warning("[\(formatter.string(from: trip.departure))....\(formatter.string(from: end))]..................\(formatter.string(from: start))")
                return TrainState.WaitForStart
            } else {
                Log.warning("Trip \(trip.name) is in past")
                Log.warning("\(formatter.string(from: start))..................[\(formatter.string(from: trip.departure)).....\(formatter.string(from: end))]")
                return TrainState.Ended
            }
        }
        return TrainState.Driving
    }
    
    func getTrainLocation(forTrip trip: TimeFrameTrip, atDate date: Date) -> (CLLocation, TrainState, Int, Double)? {
        guard let loc = zip(trip.locationArray.enumerated(),trip.locationArray.dropFirst())
            .first(where: { (arg0, next) -> Bool in
                let (_, this) = arg0
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
                if trip.locationArray.first!.departure!.timeIntervalSince(Date()) <= 900 {
                    return (trip.locationArray.first!.coords, .WaitForStart, 0, 0)
                } else {
                    Log.error("Error finding a location for Trip \(trip.name) at \(date)")
                    return nil
                }
        }
        
        
        let location = loc.0.element
        
        // Check if currently stopping
        
        if location is StopOver {
            let stopover = (location as! StopOver)
            if stopover.arrival?.timeIntervalSince(date) ?? 1 <= 0 && stopover.departure!.timeIntervalSince(date) > 0 {
                Log.debug("[\(trip.name)] Currently idling at: \(stopover.name) til \(stopover.departure!) [\(stopover.departure!.timeIntervalSince(date)) seconds]")
                return (stopover.coords, .Stopped(stopover.departure!), loc.0.offset, 0)
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
        
        return (CLLocation(latitude: newLat, longitude: newLon), .Driving, loc.0.offset, secondsIntoSection)
    }
}
