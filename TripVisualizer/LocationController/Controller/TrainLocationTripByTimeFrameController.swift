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
This Controller calculates the approximate train position based on a fixed time. 
 */
public class TrainLocationTripByTimeFrameController: TrainLocationProtocol, Updateable  {
    
    // Seconds that a scheduled train gets displayed before actual departure
    var GRACE_PERIOD = 1800.0
    
    public var dateGenerator: () -> Date

    public typealias T = TimeFrameTrip
    public typealias P = TripProvider<T>

    public weak var delegate: TrainLocationDelegate?
    public var uid: UUID
    
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
        self.uid = UUID()
    }
    
    public func remove(trip: TimeFrameTrip) {
        self.timer?.invalidate()
        self.trips.remove(trip)
        self.delegate?.removeTripFromMap(forTrip: trip)
        self.start()
    }
    
    public func remove(trip: TimeFrameTrip, reason: TrainState) {
        let data = TripData(location: nil, state: reason, arrival: -1, delay: 0)
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
    
    public func getArrivalInSeconds(forTrip trip: T, userPosInArray: Int, trainPos: Int, secondsToDeparture: Double) -> TimeInterval? {
        /**
         Tries to get the next stop facing from the users position, fetches the time of next arrivals and substracts the time that is needed to get there
         */
        guard let nextStop = trip.locationArray[userPosInArray...].enumerated().first(where: { $0.element is StopOver && ($0.element as? StopOver)?.arrival != nil }) else {
            return nil
        }
        
        let nextStopDate = (nextStop.element as! StopOver).arrival!
        
        /**
         The upper array slice returns the first stop-array-location with an offset, based on the user position, we have to add this offset to the next calculation
         Example: User is on ArrayPosition 16, next stop is on ArrayPosition 54, the offset of the slice is +16 = Offset of First stop is (54-16) = 38
         Also we have to omit the stopover, otherwise we would calculate the needed time to tne next point after the first stopover
         **/
        let missingStepsToFirstStop = (userPosInArray)
        let offset = trip.locationArray[userPosInArray...(missingStepsToFirstStop+nextStop.offset)].dropLast().map({$0.durationToNext!}).reduce(0,+)
        
        // If the departure date is in future: Use the Departure Date for calculation, if trip has started, use the current time
        let date = secondsToDeparture > 0 ? trip.departure : self.dateGenerator()
        //Calculation: Time of next stop minus the time it would take for the train to travel from user position to that stop.
        let timeWhenTrainPassesUser = nextStopDate.addingTimeInterval(-offset)
        //Now Calculate how long it takes the train to arrive at that date, based on the current time(if trip is in progress), or the scheduled departure + time til departure
        return timeWhenTrainPassesUser.timeIntervalSince(date) + secondsToDeparture
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
                currentTrainLoc.distance(from: nextSection.coords) // Remaining distance to next Section
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
            case .Driving, .Stopped(_), .WaitForStart(_):
                if let data = self.getTrainLocation(forTrip: trip, atDate: self.dateGenerator()) {
                    
                    var tripData: TripData
                    if let currentLocation = self.currentUserLocation {
                        //Currently only on top of polyline point, might be off if user is between points that are far away
                        let userPosInArray = trip.shortestDistanceArrayPosition(forUserLocation: currentLocation)
                        let timeTilDeparture = trip.departure.timeIntervalSince(self.dateGenerator())
                        let time = self.getArrivalInSeconds(forTrip: trip, userPosInArray: userPosInArray, trainPos: data.arrayPostition, secondsToDeparture: timeTilDeparture > 0 ? timeTilDeparture : 0)
                        let distance = self.getDistance(forTrip: trip, arrayPosTrain: data.arrayPostition, arrayPosUser: userPosInArray, currentTrainLoc: data.currentLocation)
                        tripData = TripData(location: data.currentLocation, state: data.trainState, arrival: time ?? -1, distance: distance, delay: data.delay )
                    } else {
                        tripData = TripData(location: data.currentLocation, state: data.trainState, arrival: -1, delay: data.delay)
                    }
                    self.delegate?.trainPositionUpdated(forTrip: trip, withData: tripData, withDuration: 1)
                } else {
                    Log.info("Gonna remove Trip \(trip) from set, because time is invalid")
                    self.remove(trip: trip, reason: .Ended)
                }
            case .Ended:
                self.remove(trip: trip, reason: .Ended)
            case .DepartsToLate:
                self.remove(trip: trip, reason: .DepartsToLate)
            }
        }
    }
    
    public func fetchServer() {
        self.delegate?.onUpdateStarted()
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
        
        let remaining = set.intersection(self.trips)
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
        
        // Filter out trips that are to far away from user
        if let userPosition = self.currentUserLocation {
            self.trips = self.trips.filter { (trip) -> Bool in
                let distance = trip.shorttestDistanceToTrack(forUserLocation: userPosition)
                if Int(distance) > UserPrefs.getMaxDistance() {
                    Log.info("[\(trip.name) - \(trip.tripId)] filtered because track too far away from user")
                    self.delegate?.removeTripFromMap(forTrip: trip)
                }
                
                return Int(distance) <= UserPrefs.getMaxDistance()
            }
        }
        
        self.start()
        
        if self.trips.isEmpty {
            /*
             Not trips remaining, either no track was in range, or no trains are currently driving
             on it.
             */
            self.delegate?.onUpdateEnded(withResult: .noTripsFound)
        }
        
        self.trips.forEach { self.delegate?.drawPolyLine(forTrip: $0) }
    }
    
    public func register(trip: T) {
        self.trips.insert(trip)
    }
    
    public func setDataProvider(withProvider provider: TripProvider<TimeFrameTrip>) {
        self.dataProvider = provider
        self.dataProvider?.setDeleate(delegate: self)
    }
    
    public func onNewClientRegistered(_ client: TrainLocationDelegate) {
        
        Log.info("\(client.id) registered at TripTimeframeController, send initial data to sync client")
        self.trips.forEach { (trip) in
            client.drawPolyLine(forTrip: trip)
        }
    }

}

//Mark: -- Update Handling

extension TrainLocationTripByTimeFrameController: TrainDataProviderDelegate {
    public func onTripsUpdated(result: TripVisualizer.Result) {
        Log.info("Trips got updated")
        switch result {
        case .success:
            self.update()
        case .error(let errorDescription):
            Log.error(errorDescription)
        case .noTripsFound:
            Log.error("No trips found")
        }
        
        self.delegate?.onUpdateEnded(withResult: result)
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
            if start.timeIntervalSince(now) > GRACE_PERIOD {
                Log.warning("Trip \(trip.name) departure date exceeds grace period, Now: \(formatter.string(from: now))...........Trip Bounds: [\(formatter.string(from: trip.departure))....\(formatter.string(from: end))]")
                return TrainState.DepartsToLate
            }
            else if start.timeIntervalSince(now) > 0 {
                Log.debug("Trip \(trip.name) is in future, Now: \(formatter.string(from: now))...........Trip Bounds: [\(formatter.string(from: trip.departure))....\(formatter.string(from: end))]")
                return TrainState.WaitForStart(start.timeIntervalSince(now))
            } else {
                Log.warning("Trip \(trip.name) is in past, Trip Bounds: [\(formatter.string(from: trip.departure))....\(formatter.string(from: end))].............Now: \(formatter.string(from: now))")
                return TrainState.Ended
            }
        }
        return TrainState.Driving(nil)
    }
    
    func getTrainLocation(forTrip trip: TimeFrameTrip, atDate date: Date) -> (currentLocation: CLLocation, trainState: TrainState, arrayPostition: Int, secondsInsideSection: Double, delay: Int)? {
        
        //Trip did not start yet:
        if trip.departure.timeIntervalSince(date) > 0 {
            return (trip.locationArray.first!.coords, .WaitForStart(trip.departure.timeIntervalSince(date)), 0, 0, 0)
        }
        
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
                    
                    if this.departure == nil || next.departure == nil {
                        Log.warning("\(trip.name) | \(trip.tripId): Departure date of a stopover is nil!")
                        return false
                    }
                    
                    return this.departure!.timeIntervalSince(date) <= 0 && next.departure!.timeIntervalSince(date) > 0
                }
            }) else {
                //If Journey has ended
                if ((trip.locationArray.last as? StopOver)?.arrival ?? Date(timeIntervalSince1970: 0)).timeIntervalSince(date) <= 0 {
                    return (trip.locationArray.last!.coords, .Ended, 0, 0, (trip.locationArray.last! as! StopOver).arrivalDelay ?? 0)
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
                return (stopover.coords, .Stopped(stopover.departure!, stopover.name), loc.0.offset, 0, stopover.arrivalDelay ?? 0)
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
        if let nextStopOver = (trip.locationArray[loc.0.offset...].dropFirst().first(where: {$0 is StopOver}) as? StopOver) {
            return (CLLocation(latitude: newLat, longitude: newLon), .Driving(nextStopOver.name), loc.0.offset, secondsIntoSection, nextStopOver.arrivalDelay ?? 0)
        } else {
            return (CLLocation(latitude: newLat, longitude: newLon), .Driving(nil), loc.0.offset, secondsIntoSection, 0)
        }
        
    }
}
