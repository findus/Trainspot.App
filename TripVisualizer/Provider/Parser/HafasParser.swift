//
//  HafasParser.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 05.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftyJSON

public class HafasParser {
    
// MARK: TripJourney parsing
    
    public enum HafasParseError : Error {
        case DecodeError(errormessage: String)
    }
    
    /**
     This method generates a so called timeline. A Timeline holds a list with all Path and Stopovers.
     Stopovers are getting sanitized if departure or arrival time is missing, and a placeholder value (-2) is getting set for the distance to the next feature, that will be calculated later
     It also holds so called animation data, .
     */
    public static func generateTimeLine(forTrip trip: HafasTrip) throws -> Timeline {
        
        let tripName = trip.line.name
        let stops = trip.stopovers
        guard let polyline = trip.polyline?.features else {
            let error = "[\(tripName)] Has no Polyline"
            Log.error(error)
            throw AnimationCalculationError.PolyLineNotFound(message: error)
        }
        
        guard let date = trip.departure else {
            let error = "[\(tripName)] Could not parse departure date"
            Log.error(error)
            throw AnimationCalculationError.DepartureDateNotFound(message: error)
        }
      
        do {
            
            var line = try polyline.enumerated().map { (offset,feature) -> Feature in
                
                func isFirstStop() -> Bool {
                    return offset == 0
                }
                
                func isLastStop() -> Bool {
                    return offset == polyline.count - 1
                }
                                
                let lat = feature.geometry.coordinates[1]
                let lon = feature.geometry.coordinates[0]
                
                if feature.isStopOver() {
                    
                    guard let stopOver = stops.filter({ $0.stop.id == feature.properties!.id }).first else {
                        throw HafasParseError.DecodeError(errormessage: "[\(tripName) StopID: \(feature.properties!.id)] Could not find stopOver for this id")
                    }
                    
                    let name = stopOver.stop.name
                    
                    var departure = stopOver.departure
                    if !isLastStop() && departure == nil {
                        Log.warning("[\(tripName) Substop: \(name)] Could not parse departure date in middle of trip, will use arrival date as departure date")
                        guard let arrival = stopOver.arrival else {
                            throw HafasParseError.DecodeError(errormessage: "[\(tripName) Substop: \(name)] No Departure AND Arrival Date found")
                        }
                        departure = arrival
                    }
                    
                    var arrival = stopOver.arrival
                    if !isFirstStop() && arrival == nil {
                        Log.warning("[\(tripName) Substop: \(name)] Could not parse arrival date in middle of trip, using departure date instead")
                        guard let departure = stopOver.departure else {
                            throw HafasParseError.DecodeError(errormessage: "[\(tripName) Substop: \(name)] No Departure AND Arrival Date found")
                        }
                        arrival = departure
                    }
                    
                    var newstop = StopOver(distanceToNext: -2, name: name, coords: CLLocation(latitude: lat, longitude: lon) , arrival: arrival, departure: departure, departureDelay: stopOver.departureDelay)
                    
                    if let delay =  stopOver.arrivalDelay  {
                        newstop.arrivalDelay = delay
                    }
                    
                    return newstop
                               
                } else {
                    return Path(distanceToNext: -2, coords: CLLocation(latitude: lat, longitude: lon))
                }
            }
            
            if (line.last is StopOver) == false {
                Log.warning("\(trip.line.name) Last Entry is not a StopOver")
            }
            
            if (line.first is StopOver) == false {
                Log.warning("\(trip.line.name) First Entry is not a StopOver")
            }
            
            /**
             Delay check: Currently the delay indicators are getting nulled if a train departs from a certain stop. Thats leads to problems to the calculation
             of the current train position, because the simulator now works with "false" starting times for this section
             
             For Example: An ICE arrives with +50 at Hannover and Departs with +50. Next Stop is Göttingen with +49
             Now the Depature-Time in Hannover gets resettet to the original time.
             For the simulation, the actual time needed from hannover to göttingen is 50 Minutes longer then  is really is.
             
             To prevent this issue, every former stops time gets the delay of the first delayed stop as offset
             
             //TODO might brake next stopover if really has 0 delay (instead of nil as value)
             */
            if let (firstDelayIndex,firstStopOverWithDelay) = line
                .enumerated()
                .first(where: { ($0.element is StopOver) && (($0.element as! StopOver).hasArrivalDelay() || ($0.element as! StopOver).hasDepartureDelay()) }) {
               
                let delayStop = firstStopOverWithDelay as! StopOver
                
                line = line.enumerated().map { (offset,feature) -> Feature in
                    if feature is StopOver && offset < firstDelayIndex {
                        let f = (feature as! StopOver)
                        return StopOver(
                            distanceToNext: f.distanceToNext,
                            durationToNext: f.durationToNext,
                            name: f.name,
                            coords: f.coords,
                            arrival: f.arrival?.addingTimeInterval(Double(delayStop.arrivalDelay ?? delayStop.departureDelay ?? 0)),
                            departure: f.departure?.addingTimeInterval(Double(delayStop.departureDelay ?? delayStop.arrivalDelay ?? 0)),
                            arrivalDelay: delayStop.arrivalDelay ?? delayStop.departureDelay,
                            departureDelay: delayStop.departureDelay ?? delayStop.arrivalDelay
                        )
                    } else {
                        return feature
                    }
                }
            }
            
            Log.debug("Generate Animation Data for: \(tripName)")
            let animationData = generateAnimationData(fromFeatures: line)
            
            return Timeline(name: tripName, line: line, animationData: animationData ,departure: date)
            
        } catch {
            Log.error(error)
            throw error
        }
        
    }
    
    public struct Section {
        var time: TimeInterval
        var distance: Double
        var distances: Array<Double>
        func distancePerSecond() -> Double {
            return distance / time
        }
    }
    
    public enum AnimationCalculationError: Error {
        case NoDurationFound(message : String)
        case DepartureDateNotFound(message : String)
        case PolyLineNotFound(message: String)
    }
    
    /**
     Returns an Array of features where every feature has the needed duration and distance to the next Feature and the current location
     */
    public static func getFeaturesWithDates(forFeatures features: Array<Feature>, andAnimationData animationData: Array<AnimationData>, forTrip trip: HafasTrip) throws -> Array<Feature> {
        
        try zip(features, animationData).enumerated().reduce([Feature]()) { (previousFeatureArray, tuple) -> Array<Feature> in
            
            var newFeatureArray = previousFeatureArray
            let (offset,(currentFeature, animationData)) = tuple
            
            var distance = 0.0
            
            // Check if a next feature exist in the array, if it does calculate the distance to it
            if let nextFeature = features[exist: offset+1]  {
                distance = currentFeature.coords.distance(from: nextFeature.coords)
            }
            
            // Check if this is the first stopover, or if we already are "in the middle of the trip"
            if let last = previousFeatureArray.last {
                let lastDate = last.departure
                
                if currentFeature is StopOver {
                    
                    let stop = currentFeature as! StopOver
                    
                    var stopover = StopOver(
                        distanceToNext: distance,
                        name: stop.name,
                        coords: stop.coords,
                        arrival: stop.arrival,
                        departure: stop.departure,
                        arrivalDelay: stop.arrivalDelay,
                        departureDelay: stop.departureDelay
                    )
                    
                    stopover.durationToNext = animationData.duration
                    newFeatureArray.append(stopover)
                    return newFeatureArray
                } else {
                    
                    guard let durationToNext = last.durationToNext else {
                        let errormsg = "[\(trip.line.name)] Could not find the duration from \(last.coords)"
                        throw AnimationCalculationError.NoDurationFound(message: errormsg)
                    }
                    
                    let path = Path(distanceToNext: distance,
                                    durationToNext: animationData.duration,
                                    departure: lastDate!.addingTimeInterval(durationToNext),
                                    coords: currentFeature.coords,
                                    lastBeforeStop: false)
                    
                    newFeatureArray.append(path)
                    return newFeatureArray
                }
            } else {
               
                // If it is the first entry create the first stopover
                let stop = currentFeature as! StopOver
                
                var st = StopOver(distanceToNext: distance,
                                  name: stop.name,
                                  coords: stop.coords,
                                  arrival: stop.arrival,
                                  departure: stop.departure,
                                  arrivalDelay: stop.arrivalDelay,
                                  departureDelay: stop.departureDelay
                )
                
                st.durationToNext = animationData.duration
                newFeatureArray.append(st)
                
                return newFeatureArray
            }
        }
    }
    
    public static func generateAnimationData(fromFeatures features: Array<Feature>) -> Array<AnimationData> {
        
        // Get all StopOvers inside the Path
        let stops = features.enumerated().filter( { $0.element is StopOver } )
        
        // Get the array positions of all these Stops
        let station_array_positions = zip(stops, stops.dropFirst()).map( { ($0.0.offset, $0.1.offset) } )
        
        let sections = station_array_positions.map { (tuple) -> Section in
            let (departure, arrival) = tuple
            let slice = features[departure...arrival]
            
            // Calculate the distances between each polyline dots....
            let distances = zip(slice, slice.dropFirst()).map { (loc1, loc2) -> Double in
                return loc1.coords.distance(from: loc2.coords)
            }
            
            // ... and Calculate the Distance between the two stops
            let wholeDistance = distances.reduce(0, +)
            
            // Calculate the time needed to get from stopX to stopX+1 in seconds
            let time = (features[arrival] as! StopOver).arrival!.timeIntervalSince(((features[departure] as! StopOver).departure!))
            
            return Section(time: time, distance: wholeDistance, distances: distances)
            
        }
        
        let animationData = sections.map { (s) -> [AnimationData] in
            let distancePerSecond = s.distancePerSecond()
            return s.distances.enumerated().map { (i,singleDistance) -> AnimationData in
                if i == 0 {
                    return AnimationData(vehicleState: .Accelerating , duration: singleDistance / distancePerSecond)
                } else if i == s.distances.count - 1 {
                    return AnimationData(vehicleState: .Stopping , duration: singleDistance / distancePerSecond)
                } else {
                    return AnimationData(vehicleState: .Driving , duration: singleDistance / distancePerSecond)
                }
            }
            
        }
        
        var merged = Array(animationData.joined())
        //Append dummy Data for last Feature Stop
        merged.append(AnimationData(vehicleState: .Stopping, duration: 0))
        return merged
    }
            
    public static  func loadJourneyTrip(fromHAFASTrips: Array<HafasTrip>) -> Array<JourneyTrip> {
        
        let trips = fromHAFASTrips.compactMap({ (trip) -> JourneyTrip? in
            let name = trip.line.name
            
            guard let polyline =  trip.polyline else {
                Log.error("\(trip.line.name) has no polyline")
                return nil
            }
            
            let coords = polyline.features.map { MapEntity(name: "line", tripId: trip.id, location: CLLocation(latitude: $0.geometry.coordinates[1], longitude: $0.geometry.coordinates[0]))  }
            
            guard let tl = try? generateTimeLine(forTrip: trip)  else {
                Log.error("[\(name)] Parse Error, could not generate Timeline, wil exclude this trip")
                return nil
            }
            
            return JourneyTrip(withDeparture: tl.departure, andName: tl.name, andTimeline: tl , andPolyline: coords, andID: trip.id,andDestination: trip.destination.name, andDelay: trip.arrivalDelay)
        })
        
        return trips
        
    }
    
    //TODO for journeys / Mocking
    public static func loadTimeFrameTrip(fromHafasTrips array: Set<HafasTrip>) -> Set<TimeFrameTrip> {
        
        let tripArray = array.compactMap({ (trip) -> TimeFrameTrip? in
            
            guard let polyline =  trip.polyline else {
                Log.error("\(trip.line.name) has no polyline")
                return nil
            }
            
            let coords = polyline.features.map { MapEntity(name: "line", tripId: trip.id, location: CLLocation(latitude: $0.geometry.coordinates[1], longitude: $0.geometry.coordinates[0]))  }
            
            do {
                let timeline = try generateTimeLine(forTrip: trip)
                let locationBasedFeatures = try getFeaturesWithDates(forFeatures: timeline.line, andAnimationData: timeline.animationData, forTrip: trip)
                return TimeFrameTrip(withDeparture: timeline.departure, andName: timeline.name, andPolyline: coords,andLocationMapping: locationBasedFeatures, andID: trip.id, andDestination: trip.destination.name, andDelay: trip.arrivalDelay)
            } catch {
                Log.error(error.localizedDescription)
                return nil
            }
            
        })
        
        return Set(tripArray)
    }
    
    public static func getJourneys(fromJSON json: JSON) -> Array<Journey> {
        json.arrayValue
            .filter({ ["nationalExpress", "national", "regionalExp", "regional"].contains(where: $0["line"]["product"].stringValue.contains)  })
            .compactMap {
                if $0["cancelled"].exists() {
                    Log.warning("\($0["stop"]["name"]) cancelled")
                    return nil
                }
                return Journey(from_id: $0["stop"]["id"].stringValue, from: $0["stop"]["name"].stringValue, to: $0["direction"].stringValue, tripID: $0["tripId"].stringValue, when: formatHafasDate(fromString: $0["when"].stringValue)!, name: $0["line"]["id"].stringValue)
        }
                
    }

}

