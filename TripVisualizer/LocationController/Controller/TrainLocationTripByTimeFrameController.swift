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
    
}

//MARK: - Delegate Methods

extension TrainLocationTripByTimeFrameController {
    
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

    public func getTrip(withID id: String) -> T? {
        return trips.first(where: { $0.tripId == id })
    }

    public func setCurrentLocation(location: CLLocation) {
        self.currentUserLocation = location
    }
        
    @objc func onTick(timer: Timer) {
        self.trips.forEach { (trip) in
            switch self.isTripInBounds(trip: trip) {
            case .Driving, .Stopped(_), .WaitForStart(_):
                self.calculateAndSendTrainPositionData(forTrip: trip)
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
    
    public func refreshSelected(trips: Array<TimeFrameTrip>) {
        self.delegate?.onUpdateStarted()
        self.dataProvider?.updateExistingTrips(trips)
    }

    public func update() {
        
        //Stop timer while updating entries
        self.timer?.invalidate()
        
        guard let trips = dataProvider?.getAllTrips() else {
            Log.error("Error retreiving trips")
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
        
        self.trips = new.union(remaining)
        
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
    public func onTripSelectionRefreshed(result: Result) {
        self.update()
    }
    
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
                Log.trace("Trip \(trip.name) is in future, Now: \(formatter.string(from: now))...........Trip Bounds: [\(formatter.string(from: trip.departure))....\(formatter.string(from: end))]")
                return TrainState.WaitForStart(start.timeIntervalSince(now))
            } else {
                Log.warning("Trip \(trip.name) is in past, Trip Bounds: [\(formatter.string(from: trip.departure))....\(formatter.string(from: end))].............Now: \(formatter.string(from: now))")
                return TrainState.Ended
            }
        }
        return TrainState.Driving(nil)
    }
    

}

// MARK: - Calculation Methods

extension TrainLocationTripByTimeFrameController {
    
    struct TrainLocationData {
        var currentLocation: CLLocation
        var trainState: TrainState
        var delay: Int
        var metersIntoPath: Double
        var arrayPostition: Int
        var currentSection: OffsetCalculator.Section? = nil
    }
    
    /**
     Extracts section data from the trip beginning from the provided stop up to the next stop
     */
    private func getSection(forTrip trip: T, andLastStop lastStop: StopOver) -> OffsetCalculator.Section {
        
        let lastStopIndex = trip.locationArray.firstIndex(where: {$0.departure == lastStop.departure})
        let nextStopIndex = trip.locationArray[lastStopIndex!...].dropFirst().firstIndex(where: {$0 is StopOver})
            
        //Complete distance from prior stop to next stop
        let complete_distance = trip.locationArray[lastStopIndex!...nextStopIndex!].map({$0.distanceToNext}).dropLast().reduce(0,+)
        let complete_duration = trip.locationArray[lastStopIndex!...nextStopIndex!].map({$0.durationToNext!}).dropLast().reduce(0.0,+)
        
        return OffsetCalculator.Section(
            priorStopOverArrayPosition: lastStopIndex!,
            nextStopOverArrayPosition: nextStopIndex!,
            length: complete_distance,
            duration: complete_duration
        )
    }
    
    struct TrainLocationInfo {
        var location: CLLocationCoordinate2D
        var index: Int
        var metersInto: Double
    }
    
    /**
     Calculates the estimated position of the train on a map, returns the coordinates and the meters inside the newest section
     */
    private func calculateTrainLocationWithAcceleration(forTrip trip: T,
                                                        forSection section: OffsetCalculator.Section)
    -> TrainLocationInfo {
       
        let secondsInSection = self.dateGenerator()
            .timeIntervalSince(trip.locationArray[section.priorStopOverArrayPosition].departure!)
        
        let adjusted_distance = OffsetCalculator().getPositionForTime(secondsInSection,
                                                                      forSection: section)
                
        var addedDistances = 0.0
        // Current index of the section the train is inside
        var currentTrainIndex = 0
        // The train is that many meters inside the section
        var metersIntoPath = 0.0
        
        // Iterates over the location array and searches for the current path the train is on
        for entry in trip.locationArray[section.priorStopOverArrayPosition...section.nextStopOverArrayPosition].enumerated() {
            addedDistances += entry.element.distanceToNext
            if addedDistances >= adjusted_distance {
                let remainder = addedDistances - adjusted_distance
                metersIntoPath = entry.element.distanceToNext - remainder
                // Never return a negative index
                currentTrainIndex = entry.offset - 1 < 0 ? 0 : entry.offset
                break
            }
        }

        let newIndex = section.priorStopOverArrayPosition + currentTrainIndex
        let currentTrainSection = trip.locationArray[newIndex]
        
        let percentageOfPathComplete = metersIntoPath / currentTrainSection.distanceToNext
        
        //Starting coords of this section
        let thiscoords = trip.locationArray[section.priorStopOverArrayPosition + currentTrainIndex].coords
        //Starting coords of next section
        let nextcoords = trip.locationArray[section.priorStopOverArrayPosition + currentTrainIndex + 1].coords
        
        //Percentage offset between these two coordinates
        let newLat = thiscoords.coordinate.latitude + ((nextcoords.coordinate.latitude - thiscoords.coordinate.latitude) * percentageOfPathComplete)
        let newLon = thiscoords.coordinate.longitude + ((nextcoords.coordinate.longitude - thiscoords.coordinate.longitude) * percentageOfPathComplete)
                
        return TrainLocationInfo(location: CLLocationCoordinate2D(latitude: newLat, longitude: newLon),
                                 index: newIndex ,
                                 metersInto: metersIntoPath)
    }
    
    private func getCurrentUserSection(forTrip trip: T, forUserPosition position: CLLocation ) -> OffsetCalculator.Section {
        let userPosInArray = trip.shortestDistanceArrayPosition(forUserLocation: position)
        var result = trip.locationArray[...userPosInArray].reversed().first(where: { $0 is StopOver })!
        //if stop is the last stop use the previous as start
        if (trip.locationArray.last as! StopOver).name == (result as! StopOver).name {
            result = trip.locationArray[...userPosInArray].reversed().dropFirst().first(where: { $0 is StopOver })!
        }
        
        return getSection(forTrip: trip, andLastStop: result as! StopOver)
    }
    
    private func getCurrentTrainLocationInArray(forTrip trip: T, atData date: Date) -> (Int, Feature, StopOver)? {
      
        var lastStopOver: StopOver? = nil
        
        let location = zip(trip.locationArray.enumerated(),trip.locationArray.dropFirst())
            .first(where: { (enumeratedLocationArray, nextPosition) -> Bool in
                let (_, thisPosition) = enumeratedLocationArray
                
                if thisPosition is Path && nextPosition is StopOver {
                    // Train is inside a section right before a stopover
                    
                    /**
                     Map Against Arrival Data:
                    Section Start       Train     Arrival       Departure
                        |__________*_____|     Stop     |________> Time .
                      15:00              15:02    15:03          15:04
                     */
                                        
                let isInThisSection = (thisPosition as! Path).departure!.timeIntervalSince(date) <= 0 && (nextPosition as! StopOver).arrival!.timeIntervalSince(date) > 0
                               
                    return isInThisSection
               
                } else if thisPosition is StopOver {
                    // Train is currently stopping or departs inside first section after departure
                    
                    /**
                    Map Against Arrival Data:
                    Section Start                     Arrival       Departure
                        |________________|     Train     |________> Time .
                    15:00                                 15:03          15:04
                    */
                   
                    lastStopOver = thisPosition as? StopOver
                 
                    //Returns true if the train is currently stopping at this point....
                    let stopOverArrivalDateInPast = ((lastStopOver!).arrival?.timeIntervalSince(date) ?? 1 <= 0)
                    let stopOverDepartueDateInFuture = ((lastStopOver!).departure!.timeIntervalSince(date) > 0)
                    
                    //Or if the the train departet and is between the stop and the next polyline dot
                    let stopOverDepartureInPast =  (lastStopOver!).departure!.timeIntervalSince(date) <= 0
                    let nextPositionDepartureInFuture = (nextPosition).departure!.timeIntervalSince(date) >= 0
                    
                    let isInThisSection =
                        (stopOverArrivalDateInPast && stopOverDepartueDateInFuture) || (stopOverDepartureInPast && nextPositionDepartureInFuture)
                    
                    return isInThisSection

                } else {
                    // Train is currently moving in a section
                    if lastStopOver?.departure == nil || nextPosition.departure == nil {
                        Log.warning("\(trip.name) | \(trip.tripId): Departure date of a stopover is nil!")
                        return false
                    }
                    
                    let isInThisSection = lastStopOver!.departure!.timeIntervalSince(date) <= 0 && nextPosition.departure!.timeIntervalSince(date) > 0
                        
                    return isInThisSection
                }
            })
        
        // Check if a previous stopover was found and if  the train is currentla somwhere inside a section
        guard let lastStop = lastStopOver,
              let trainIndexInArray = location?.0.offset,
              let currentFeature = location?.0.element else {
            return nil
        }
    
        return (trainIndexInArray, currentFeature, lastStop)
    }
    
    
    /**
     Returns the current lcoation of the train inside its locationArray at a specific date
     */
    func getTrainLocation(forTrip trip: TimeFrameTrip, atDate date: Date) -> TrainLocationData? {
        
        func tripNotStartedYet() -> Bool {
            return trip.departure.timeIntervalSince(date) > 0
        }
        
        //Return if Trip did not start yet.
        if tripNotStartedYet() {
            return TrainLocationData(currentLocation: trip.locationArray.first!.coords,
                                     trainState: .WaitForStart(trip.departure.timeIntervalSince(date)),
                                     delay: 0,
                                     metersIntoPath: 0,
                                     arrayPostition: 0
            )
        }
       
        // get the current section-index of the train with additional infos like latest passed stopover and the current section object
        guard let (currentFeatureIndex, currentFeature, lastStop) = self.getCurrentTrainLocationInArray(forTrip: trip, atData: date) else {
            
            func didJourneyAlreadyEnd() -> Bool {
                return ((trip.locationArray.last as? StopOver)?.arrival ?? Date(timeIntervalSince1970: 0)).timeIntervalSince(date) <= 0
            }
           
            //If Journey has ended
            if didJourneyAlreadyEnd() {
                
                return TrainLocationData(currentLocation: trip.locationArray.last!.coords,
                                         trainState: .Ended,
                                         delay: (trip.locationArray.last! as! StopOver).arrivalDelay ?? 0,
                                         metersIntoPath: 0,
                                         arrayPostition: trip.locationArray.count - 1
                )
                
            } else {
                Log.error("Error finding a location for Trip \(trip.name) at \(date)")
                return nil
            }
        }
        
        let section = getSection(forTrip: trip, andLastStop: lastStop)

        // Check if currently stopping
        if currentFeature is StopOver {
            let stopover = (currentFeature as! StopOver)
           
            if stopover.arrival?.timeIntervalSince(date) ?? 1 <= 0 && stopover.departure!.timeIntervalSince(date) > 0 {
                
                Log.trace("[\(trip.name)] Currently idling at: \(stopover.name) til \(stopover.departure!) [\(stopover.departure!.timeIntervalSince(date)) seconds]")
                
                return TrainLocationData(currentLocation: stopover.coords,
                                         trainState: .Stopped(stopover.departure!, stopover.name),
                                         delay: stopover.departureDelay ?? 0,
                                         metersIntoPath: 0,
                                         arrayPostition: currentFeatureIndex,
                                         currentSection: section)
            }
        }
                
        let newPositionData = self.calculateTrainLocationWithAcceleration(forTrip: trip, forSection: section)
        
        #if MOCK
        let current_distance = trip.locationArray[lastStopIndex!...currentTrainPositionIndex!]
            .dropFirst().map({$0.distanceToNext})
            .reduce(0.0,+)
        
        let current_duration = trip.locationArray[lastStopIndex!...currentTrainPositionIndex!]
            .dropFirst()
            .map({$0.durationToNext!})
            .reduce(0.0,+)
       
        print("\(trip.name): \((trip.locationArray[lastStopIndex!] as! StopOver).name) to \((trip.locationArray[nextStopIndex!] as! StopOver).name) \(complete_distance)Meter \(complete_duration)Sekunden \(current_duration)Sekunden am fahren Lineare Distanz:\(current_distance) Angepasste Distanz:\(adjusted_distance) ArrayPos:\(index) Missing Meters:\(missingMeters)")
        #endif
        
        // Get next Stop for train info object to display next stop information
        let nextStopOver = (trip.locationArray[currentFeatureIndex...].dropFirst().first(where: {$0 is StopOver}) as? StopOver)
        
        return TrainLocationData(
            currentLocation: CLLocation(latitude: newPositionData.location.latitude, longitude: newPositionData.location.longitude),
            trainState: .Driving(nextStopOver?.name),
            delay:  nextStopOver?.arrivalDelay ?? 0,
            metersIntoPath: newPositionData.metersInto,
            arrayPostition: newPositionData.index,
            currentSection: section )
    }
    
    /**
     This method triggers all positional and time calculations and sends the results to delegate objects
     */
    private func calculateAndSendTrainPositionData(forTrip trip: T) {
        if let data = self.getTrainLocation(forTrip: trip, atDate: self.dateGenerator()) {
            
            var tripData: TripData
            if let currentLocation = self.currentUserLocation {
                
                //Currently only on top of polyline point, might be off if user is between points that are far away
                let userPosInArray = trip.shortestDistanceArrayPosition(forUserLocation: currentLocation)
                    
                let distance = self.getDistance(forTrip: trip,
                                                arrayPosUser: userPosInArray,
                                                arrayPosTrain: data.arrayPostition,
                                                metersIntoPath: data.metersIntoPath
                )
                
                let userSection = self.getCurrentUserSection(forTrip: trip, forUserPosition: currentLocation)
                   
                let arrivalDate = ArrivalCalculator<TimeFrameTrip>().getArrivalInSeconds(forTrip: trip,
                                                                                         forSection: userSection,
                                                                                         userPositionInArray: userPosInArray)
                
                tripData = TripData(location: data.currentLocation,
                                    state: data.trainState,
                                    arrival: arrivalDate.timeIntervalSince(self.dateGenerator()),
                                    distance: distance,
                                    delay: data.delay )

            } else {
               
                tripData = TripData(location: data.currentLocation,
                                    state: data.trainState,
                                    arrival: -1, delay: data.delay
                )
            }
            self.delegate?.trainPositionUpdated(forTrip: trip, withData: tripData, withDuration: 1)
        } else {
            Log.info("Gonna remove Trip \(trip) from set, because time is invalid")
            self.remove(trip: trip, reason: .Ended)
        }
    }
}

//MARK: - User Location Calculation Methods

extension TrainLocationTripByTimeFrameController {
   
    /**
     Calculates the Current Distance, of the train from the user.
     */
    private func getDistance(forTrip trip: T, arrayPosUser: Int, arrayPosTrain: Int, metersIntoPath: Double) -> Double {
        if arrayPosUser < arrayPosTrain {
            return 0 - (trip.locationArray[arrayPosUser...arrayPosTrain].dropLast().map { $0.distanceToNext }.reduce(0, +)
                + metersIntoPath)
        } else {
            return trip.locationArray[arrayPosTrain...arrayPosUser].dropLast().map { $0.distanceToNext }.reduce(0, +)
            - metersIntoPath
        }
    }
}
