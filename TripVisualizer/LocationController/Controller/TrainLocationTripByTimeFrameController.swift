//
//  TrainLocationTripByTimeFrameController.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation

/**
 This class controls trips, that have no direct binding from locations and times, for example if you download a timetable
 This Controller tries to calculate proper animations for a trip
 */
public class TrainLocationTripByTimeFrameController: TrainLocationProtocol  {
    
    private let dateGenerator: () -> Date

    public typealias T = TimeFrameTrip
    public typealias P = TripProvider<T>

    public weak var delegate: TrainLocationDelegate?
    
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
    
    public init(dateGenerator: @escaping () -> Date = Date.init) {
        self.dateGenerator = dateGenerator
    }
    
    public func remove(trip: TimeFrameTrip) {
        self.timer?.invalidate()
        self.trips.remove(trip)
        self.delegate?.removeTripFromMap(forTrip: trip)
        self.start()
    }
    
    public func remove(trip: TimeFrameTrip, reason: TrainState) {
        let data = TripData(location: nil, state: reason, arrival: -1)
        self.delegate?.trainPositionUpdated(forTrip: trip, withData: data, withDuration: 1)
        self.remove(trip: trip)
    }
    
    public func start() {
        Log.info("Timeframe Controller started")
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(onTick), userInfo: nil, repeats: true)
    }
    
    public func pause() {
        Log.info("Timeframe Controller paused")
        self.timer?.invalidate()
    }
    
    public func getArrivalInSeconds(forTrip trip: T, userPosInArray: Int, trainPos: Int) -> TimeInterval? {
        /**
         Tries to get the next stop facing from the users position, fetches the time of next arrivals and substracts the time that is needed to get there
         */
        guard let nextStop = trip.locationArray[userPosInArray...].enumerated().first(where: { $0.element is StopOver && ($0.element as? StopOver)?.arrival != nil }) else {
            return nil
        }
        
        let a = (nextStop.element as! StopOver).arrival!
        let offset = trip.locationArray[userPosInArray...(userPosInArray+nextStop.offset)].map({$0.durationToNext!}).reduce(0,+)
        return a.addingTimeInterval(-offset).timeIntervalSince(self.dateGenerator())
    }
    
    /**
     Calculates the Current Distance, of the train from the user.
     */
    private func getDistance(forTrip trip: T, arrayPosTrain: Int, arrayPosUser: Int, currentTrainLoc: CLLocation) -> Double {
        /**
         We need this, because the train could have already traveled a certain amount on this polyline. That why the current line is omitted and the current location distance to the next segment gets calculated
         **/
        guard let nextSection = trip.locationArray[exist: arrayPosTrain + 1] else {
            return -1
        }
        
        // Train is still in front of user
        if arrayPosTrain + 1 < arrayPosUser {
            return
                currentTrainLoc.distance(from: nextSection.coords) // Remeining distance to next Section
                +
                trip.locationArray[arrayPosTrain + 1...arrayPosUser].map({$0.distanceToNext}).reduce(0, +) // Sum of all Sections to user
        // Train has passed user
        } else if arrayPosUser < arrayPosTrain {
           return -(trip.locationArray[arrayPosUser...arrayPosTrain].map({$0.distanceToNext}).reduce(0, +) + currentTrainLoc.distance(from: trip.locationArray[arrayPosTrain].coords))
        } else {
            return arrayPosTrain < arrayPosUser ? currentTrainLoc.distance(from: nextSection.coords) : -currentTrainLoc.distance(from: trip.locationArray[arrayPosTrain].coords)
        }
    }
    
    public func setCurrentLocation(location: CLLocation) {
        self.currentUserLocation = location
    }
    
    @objc func onTick(timer: Timer) {
        self.trips.forEach { (trip) in
            switch self.isTripInBounds(trip: trip) {
            case .Driving, .Stopped(_):
                if let data = self.getTrainLocation(forTrip: trip, atDate: self.dateGenerator()) {
                    
                    var tripData: TripData
                    if let currentLocation = self.currentUserLocation {
                        //Currently only on top of polyline point, might be off if user is between points that ar far away
                        let userPosInArray = trip.shortestDistanceArrayPosition(forUserLocation: currentLocation)
                        let time = self.getArrivalInSeconds(forTrip: trip, userPosInArray: userPosInArray, trainPos: data.arrayPostition)
                        let distance = self.getDistance(forTrip: trip, arrayPosTrain: data.arrayPostition, arrayPosUser: userPosInArray, currentTrainLoc: data.currentLocation)
                        tripData = TripData(location: data.currentLocation, state: data.trainState, arrival: time ?? -1, distance: distance )
                    } else {
                        tripData = TripData(location: data.currentLocation, state: data.trainState, arrival: -1)
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
    
    public func fetchServer() {
        self.dataProvider?.update()
    }

    public func update() {
        
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
    
    public func register(trip: T) {
        self.trips.insert(trip)
    }
    
    public func setDataProvider(withProvider provider: TripProvider<TimeFrameTrip>) {
        self.dataProvider = provider
        self.dataProvider?.setDeleate(delegate: self)
    }

}

//Mark: -- Update Handling

extension TrainLocationTripByTimeFrameController: TrainDataProviderDelegate {
    public func onTripsUpdated() {
        Log.info("Trips got updated")
        self.update()
    }
}

//MARK: -- Location Tracking

extension TrainLocationTripByTimeFrameController {
    
    private func isTripInBounds(trip: TimeFrameTrip) -> TrainState {
        let start = trip.departure
        let end = (trip.locationArray.last! as! StopOver).arrival ?? Date.init(timeIntervalSince1970: 0)
        let now = self.dateGenerator()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        
        if start.timeIntervalSince(now) > 0 || end.timeIntervalSince(now) < 0 {
            if start.timeIntervalSince(now) > 0 {
                Log.warning("Trip \(trip.name) is in future, Now: \(formatter.string(from: now))...........Trip Bounds: [\(formatter.string(from: trip.departure))....\(formatter.string(from: end))]")
                return TrainState.WaitForStart
            } else {
                Log.warning("Trip \(trip.name) is in past, Trip Bounds: [\(formatter.string(from: trip.departure))....\(formatter.string(from: end))].............Now: \(formatter.string(from: now))")
                return TrainState.Ended
            }
        }
        return TrainState.Driving(nil)
    }
    
    func getTrainLocation(forTrip trip: TimeFrameTrip, atDate date: Date) -> (currentLocation: CLLocation, trainState: TrainState, arrayPostition: Int, secondsInsideSection: Double)? {
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
                // "Error" handling, if train journey has not started, or has already ended
                if trip.locationArray.first!.departure!.timeIntervalSince(self.dateGenerator()) <= 900 {
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
        
        // Calculate relative Position between to Points
        let wholeDuration = location.durationToNext!
        let departure = location.departure!
       
        let startCoords = location.coords.coordinate
        let endCoords = loc.1.coords.coordinate
        
        let secondsIntoSection = ( date.timeIntervalSince(departure) )
        
        let ratio = secondsIntoSection / wholeDuration
        
        let newLat = startCoords.latitude + ((endCoords.latitude - startCoords.latitude) * ratio)
        let newLon = startCoords.longitude + ((endCoords.longitude - startCoords.longitude) * ratio)
        
        // Get next Stop
        
        if let nextStopOver = (trip.locationArray[loc.0.offset...].first(where: {$0 is StopOver}) as? StopOver)?.name {
            return (CLLocation(latitude: newLat, longitude: newLon), .Driving(nextStopOver), loc.0.offset, secondsIntoSection)
        } else {
            return (CLLocation(latitude: newLat, longitude: newLon), .Driving(nil), loc.0.offset, secondsIntoSection)
        }
        
    }
}
