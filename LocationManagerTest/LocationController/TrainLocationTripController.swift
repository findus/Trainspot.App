//
//  TrainLocationTripController.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation
import Log

class TrainLocationTripController: TrainLocationProtocol  {
    
    typealias T = JourneyTrip
    typealias P = TripProvider<T>

    weak var delegate: TrainLocationDelegate?
        
    var trips: Array<JourneyTrip> = [JourneyTrip]()
    private var timer: Timer? = nil
    private var dataProvider: TripProvider<T>?
            
    init() {
        // self.dataProvider = MockTrainDataJourneyProvider()
    }
    
    func start() {
        self.trips.forEach { (trip) in
            self.startTrip(trip: trip)
        }
    }
    
    private func startTrip(trip: JourneyTrip) {
        
        var dateComponents = DateComponents()
        dateComponents.year = 2020
        dateComponents.month = 6
        dateComponents.day = 4
        dateComponents.hour = 15
        dateComponents.minute = 02
        dateComponents.second = 0
        
        // Create date from components
        let userCalendar = Calendar.current // user calendar
        let debugTime = userCalendar.date(from: dateComponents)!
        
        let (loc, array, d) = self.findApproximateTrainLocation(forTrip: trip, andDate: debugTime)!
        let location = CLLocation(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
        self.delegate?.trainPositionUpdated(forTrip: trip, toPosition: location, withDuration: 0)
        let position = trip.timeline.line.firstIndex(where: {$0.coords == array.coords})!
        if position > 0 {
            let animationData = trip.timeline.animationData[position - 1]
            self.startNewAnimation(forTrip: trip, toPosition: location, withDuration: animationData.duration, andArrayPosition: position)
        } else {
            //TODO diff to next minute as duration
            self.startNewAnimation(forTrip: trip, toPosition: location, withDuration: 10, andArrayPosition: position)
        }
        
    }
    
    private func startNewAnimation(forTrip trip: Trip, toPosition position: CLLocation, withDuration duration: TimeInterval, andArrayPosition pos: Int) {
        Log.debug("Animation: Di:", position ,"Du:", duration)
        self.timer?.invalidate()
        self.delegate?.trainPositionUpdated(forTrip: trip, toPosition: position, withDuration: duration)
        self.timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(eventLoop), userInfo: pos, repeats: true)
    }
    
    func update() {
        guard let trips = dataProvider?.getAllTrips() else {
            print("Error retreiving trips")
            return
        }
        
        trips.forEach { self.register(trip: $0); self.delegate?.drawPolyLine(forTrip: $0) }
    }
    
    func register(trip: T) {
        self.trips.append(trip)
//        self.delegate?.trainPositionUpdated(forTrip: trip, toPosition: trip.line[0].location, withDuration: 0)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
//            self.updateTrip(trip: trip)
//        }
    }
    
    
    @objc private func eventLoop(timer: Timer) {
        print("Event loop")
        self.trips.forEach { (trip) in
            self.updateTrip(trip: trip, arrayPosition: timer.userInfo as! Int)
        }
    }
    
    private func updateTrip(trip: JourneyTrip, arrayPosition: Int) {
        
        let newPos = arrayPosition + 1
        let animationData = trip.timeline.animationData[newPos - 1]
        
        if let stop = trip.timeline.line[arrayPosition] as? StopOver {
            if trip.atStation == false {
                trip.atStation = true
                Log.info("[\(trip.name) arrived at \(stop.name)]")
                // TODO halt time
                self.timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(eventLoop), userInfo: arrayPosition, repeats: true)
                return
            } else {
                Log.info("[\(trip.name) started moving at at \(stop.name)]")
                self.startNewAnimation(forTrip: trip, toPosition: trip.polyline[newPos].location, withDuration: animationData.duration, andArrayPosition: newPos)
                return
            }
        }
        
        if trip.polyline[newPos] is StopOver {
            // TODO stopping
        }
        
        self.startNewAnimation(forTrip: trip, toPosition: trip.polyline[newPos].location, withDuration: animationData.duration, andArrayPosition: newPos)
    }
    
    func setDataProvider(withProvider provider: TripProvider<JourneyTrip>) {
        self.dataProvider = provider
    }

}

//MARK: -- Location Tracking

extension TrainLocationTripController {
    

//
//    func generateAnimationData(atTime: Date, forNextMinutes minutes: TimeInterval, forTrip trip: JourneyTrip) -> Array<AnimationData>? {
//
//        var dateComponents = DateComponents()
//        dateComponents.year = 2020
//        dateComponents.month = 6
//        dateComponents.day = 4
//        dateComponents.hour = 14
//        dateComponents.minute = 57
//
//        // Create date from components
//        let userCalendar = Calendar.current // user calendar
//        let debugTime = userCalendar.date(from: dateComponents)!
//
//        guard
//            let position1 = findApproximateTrainLocation(forTrip: trip, andDate: debugTime),
//            let position2 = findApproximateTrainLocation(forTrip: trip, andDate: debugTime.addingTimeInterval(minutes * 60))
//            else {
//                Log.error("Could not generate animation data: Train locations could not be determined")
//                return nil
//        }
//
//        //Check if slice contains a stop
//        //let arrayPosition1 = trip.timeline.line.enumerated().find
//        let animationData = AnimationData(vehicleState: .Driving, duration: minutes * 60, location: position2.0)
//
//        return [animationData]
//    }
//
    /**
     Tries to find the exact train position on the polyine, returns the approximate position, the end of the current line the train is on, and the duration how long it would take to reach it
     */
    func findApproximateTrainLocation(forTrip trip:JourneyTrip, andDate date: Date) -> (CLLocation, Feature, Int)? {
        
        Log.debug("[\(trip.name)] Started searching for location")
        
        // let currentTime = Date() disabled for debugging
        let line = trip.timeline.line
        
        // Finds the next Stop for the current train
        let (e1, nextStop) = line.enumerated().filter({ $0.element is StopOver && ($0.element as! StopOver).arrival?.timeIntervalSince(date) ?? -1 >= 0 }).first!
        // Finds the last Stop for the current train
        let (e2, lastStop) = line.enumerated().filter({ $0.element is StopOver && ($0.element as! StopOver).departure?.timeIntervalSince(date) ?? 1 <= 0 }).last!
        
        // Calculates the time, the Train needs to travel between the last and the next stop
        let timeNeededAtoB = (nextStop as! StopOver).arrival!.timeIntervalSince((lastStop as! StopOver).departure!)
        
        // Calculates the time the train is already moving since the last stop
        let timeSinceAtoNow = date.timeIntervalSince((lastStop as! StopOver).departure!)
        
        // Calculates the time the train still needs to reach the next stop
        let remaining = timeNeededAtoB - timeSinceAtoNow
        
        let percentageMissing = remaining / timeNeededAtoB
        
        // Calculates the distance between the two stops
        let slice = line[e2...e1]
        let distance = zip(slice,slice.dropFirst()).map { (first, second) -> Double in
            return first.coords.distance(from: second.coords)
        }
        
        // Sums it
        let sum = distance.reduce(0, +)
        
        // Calculates how many kilometers the train needs to travel to reach the destination
        let missingdistance = sum * percentageMissing
        
        /**
         Tries to find the exact lat/lon of the train by adding all polyline distances together from NextStop to LastStop.
         If the sum of one additional vector length exceeds the remaining distance, the algorithm tries calculate an approximate position on the vector
         by dividing the distance vector into smaller parts
         **/
        var count = 0.0
        var nextFeature: Feature
        
        for (first, second) in zip(slice,slice.dropFirst()).reversed() {
            nextFeature = first
            
            if (count + first.coords.distance(from: second.coords) < missingdistance) {
                count += first.coords.distance(from: second.coords)
                continue
            }
            
            var temploc = second.coords
            while (count + first.coords.distance(from: temploc) > missingdistance) {
                temploc = first.coords.midPoint(withLocation: temploc)
            }
            
            count += first.coords.distance(from: second.coords)
            Log.debug("[\(trip.name)] finished searching for location")
            return (temploc,nextFeature,10)
            
            
            //            let vec = SIMD2(x: c1.coordinate.latitude - c2.coordinate.latitude, y: c1.coordinate.longitude - c2.coordinate.longitude)
            //            let normvec = simd_normalize(vec)
            //            let distance = simd_distance(simd_double8(normvec.x), simd_double8(normvec.y))
            //            let distance1 = simd_distance(simd_double8(vec.x), simd_double8(vec.y))
            //            print(normvec)
        }
        
        print(missingdistance)
        Log.error("[\(trip.name)] Could not find location")
        return nil
    }
}
