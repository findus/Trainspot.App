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
        self.timer = Timer.scheduledTimer(timeInterval: 100, target: self, selector: #selector(eventLoop), userInfo: nil, repeats: true)
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
        self.delegate?.trainPositionUpdated(forTrip: trip, toPosition: trip.line[0].location, withDuration: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.updateTrip(trip: trip)
        }
    }
    
    
    @objc private func eventLoop() {
        print("Event loop")
        self.trips.forEach { (trip) in
            self.updateTrip(trip: trip)
        }
    }
    
    private func updateTrip(trip: JourneyTrip) {
        guard let arrayPosition = trip.currentTrainPosition() else {
            return
        }
        
        var dateComponents = DateComponents()
        dateComponents.year = 2020
        dateComponents.month = 6
        dateComponents.day = 4
        dateComponents.hour = 14
        dateComponents.minute = 57
        
        // Create date from components
        let userCalendar = Calendar.current // user calendar
        let debugTime = userCalendar.date(from: dateComponents)!
        
        let animation = self.generateAnimationData(atTime: debugTime, forNextMinutes: 2, forTrip: trip)
        
        let position = self.findApproximateTrainLocation(forTrip: trip, andDate: debugTime)!.0
        let location = CLLocation(latitude: position.coordinate.latitude, longitude: position.coordinate.longitude)
        self.delegate?.trainPositionUpdated(forTrip: trip, toPosition: location, withDuration: 0)
        self.delegate?.trainPositionUpdated(forTrip: trip, toPosition: animation!.first!.location, withDuration: animation!.first!.duration)
    }
    
    func setDataProvider(withProvider provider: TripProvider<JourneyTrip>) {
        self.dataProvider = provider
    }

}

//MARK: -- Location Tracking

extension TrainLocationTripController {
    
    enum VehicleState {
        case Driving
        case Stopping
        case Accelerating
    }
        
    struct AnimationData {
        var vehicleState: VehicleState
        var duration: Double
        var location: CLLocation
    }
    
    func generateAnimationData(atTime: Date, forNextMinutes minutes: TimeInterval, forTrip trip: JourneyTrip) -> Array<AnimationData>? {
        
        var dateComponents = DateComponents()
        dateComponents.year = 2020
        dateComponents.month = 6
        dateComponents.day = 4
        dateComponents.hour = 14
        dateComponents.minute = 57
        
        // Create date from components
        let userCalendar = Calendar.current // user calendar
        let debugTime = userCalendar.date(from: dateComponents)!
        
        guard
            let position1 = findApproximateTrainLocation(forTrip: trip, andDate: debugTime),
            let position2 = findApproximateTrainLocation(forTrip: trip, andDate: debugTime.addingTimeInterval(minutes * 60))
            else {
                Log.error("Could not generate animation data: Train locations could not be determined")
                return nil
        }
        
        //Check if slice contains a stop
        //let arrayPosition1 = trip.timeline.line.enumerated().find
        let animationData = AnimationData(vehicleState: .Driving, duration: minutes * 60, location: position2.0)
        
        return [animationData]
    }
    
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
            let c1 = CLLocation(latitude: first.lat, longitude: first.lon)
            let c2 = CLLocation(latitude: second.lat, longitude: second.lon)
            return c1.distance(from: c2)
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
            let c1 = CLLocation(latitude: first.lat, longitude: first.lon)
            let c2 = CLLocation(latitude: second.lat, longitude: second.lon)
            
            if (count + c1.distance(from: c2) < missingdistance) {
                count += c1.distance(from: c2)
                continue
            }
            
            var temploc = c2
            while (count + c1.distance(from: temploc) > missingdistance) {
                temploc = c1.midPoint(withLocation: temploc)
            }
            
            count += c1.distance(from: c2)
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
