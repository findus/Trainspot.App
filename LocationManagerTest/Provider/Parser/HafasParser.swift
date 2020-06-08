//
//  HafasParser.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 05.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreLocation

class HafasParser {
    
// MARK: TripJourney parsing
    
    enum HafasParseError : Error {
        case DecodeError(errormessage: String)
    }
    
    public static func generateTimeLine(forTrip trip: JSON) -> Timeline? {
        
        let name = trip["line"]["name"].stringValue
        let stops = trip["stopovers"].arrayValue
        let polyline = trip["polyline"]["features"].arrayValue
        
        guard let date = formatHafasDate(fromString: trip["departure"].stringValue) else {
            Log.error("[\(name)] Could not parse departure date")
            return nil
        }
        
      
        do {
            
            let line = try polyline.enumerated().map { (offset,entry) -> Feature in
                
                func isFirstStop() -> Bool {
                    return offset == 0
                }
                
                func isLastStop() -> Bool {
                    return offset == polyline.count - 1
                }
                
                let stopId = entry["properties"]["id"]
                
                let lat = entry["geometry"]["coordinates"][1].doubleValue
                let lon = entry["geometry"]["coordinates"][0].doubleValue
                
                if stopId.exists() {
                    
                    guard let stopOver = stops.filter({ $0["stop"]["id"] == stopId }).first else {
                        throw HafasParseError.DecodeError(errormessage: "[\(name) StopID: \(stopId)] Could not find stopOver for this id")
                    }
                    
                    let name = stopOver["stop"]["name"].stringValue
                    
                    let departure = formatHafasDate(fromString: stopOver["departure"].string)
                    if !isLastStop() && departure == nil {
                        throw HafasParseError.DecodeError(errormessage: "[\(name) Substop: \(name)] Could not parse departure date")
                    }
                    
                    let arrival =  formatHafasDate(fromString: stopOver["arrival"].string)
                    if !isFirstStop() && arrival == nil {
                        throw HafasParseError.DecodeError(errormessage: "[\(name) Substop: \(name)] Could not parse arrival date")
                    }
                               
                    return StopOver(name: name, coords: CLLocation(latitude: lat, longitude: lon) , arrival: arrival, departure: departure)
                } else {
                    return Path(coords: CLLocation(latitude: lat, longitude: lon))
                }
            }
            
            Log.info("Generate Animation Data for: \(name)")
            let animationData = generateAnimationData(fromFeatures: line)
            
            return Timeline(name: name, line: line, animationData: animationData ,departure: date)
            
        } catch {
            Log.error(error)
            return nil
        }
        
        
        return nil
    }
    
    struct Section {
        var time: TimeInterval
        var distance: Double
        var distances: Array<Double>
        func distancePerSecond() -> Double {
            return distance / time
        }
    }
    
    /**
     Returns an Array of features where every feature has the needed duration to the next Feature and the current location
     */
    public static func getFeaturesWithDates(forFeatures features: Array<Feature>, andAnimationData animationData: Array<AnimationData>) -> Array<Feature> {
        zip(features, animationData).reduce([Feature]()) { (prev, tuple) -> Array<Feature> in
            var newArray = prev
            if let last = prev.last {
                let lastDate = last.departure
                
                if tuple.0 is StopOver {
                    let stop = tuple.0 as! StopOver
                    var st = StopOver(name: stop.name, coords: stop.coords, arrival: stop.arrival, departure: stop.departure)
                    st.durationToNext = tuple.1.duration
                    newArray.append(st)
                    return newArray
                } else {
                    let d = Path(durationToNext: tuple.1.duration, departure: lastDate!.addingTimeInterval(last.durationToNext!), coords: tuple.0.coords, lastBeforeStop: false)
                    newArray.append(d)
                    return newArray
                }
            } else {
                let stop = tuple.0 as! StopOver
                var st = StopOver(name: stop.name, coords: stop.coords, arrival: stop.arrival, departure: stop.departure)
                st.durationToNext = tuple.1.duration
                newArray.append(st)
                return newArray

            }
        }
    }
    
    public static func generateAnimationData(fromFeatures features: Array<Feature>) -> Array<AnimationData> {
        
        let stops = features.enumerated().filter( { $0.element is StopOver } )
        let station_array_positions = zip(stops, stops.dropFirst()).map( { ($0.0.offset, $0.1.offset) } )
        let sections = station_array_positions.map { (e) -> Section in
            let (departure, arrival) = e
            let slice = features[departure...arrival]
            
            
            let distances = zip(slice, slice.dropFirst()).map { (loc1, loc2) -> Double in
                return loc1.coords.distance(from: loc2.coords)
            }
            
            let wholeDistance = distances.reduce(0, +)
            
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

        return Array(animationData.joined())
    }
            
    public static  func loadJourneyTrip(fromJSON json: JSON) -> Array<JourneyTrip>? {
        
        let trips = json.arrayValue
            .filter({ $0["line"]["id"].stringValue != "bus-sev" })
            .filter({ $0["line"]["name"].stringValue != "Bus SEV" })
            .compactMap { (json) -> JourneyTrip in
                
                let name = json["line"]["name"].stringValue

                let coords = json["polyline"]["features"].arrayValue.map { MapEntity(name: "line", location: CLLocation(latitude: $0["geometry"]["coordinates"][1].doubleValue, longitude: $0["geometry"]["coordinates"][0].doubleValue ))  }
                
                guard let tl = generateTimeLine(forTrip: json) else {
                    Log.error("[\(name)] Parse Error, could not generate Timeline, wil exclude this trip")
                }
                
                return JourneyTrip(withDeparture: tl.departure, andName: tl.name, andTimeline: tl , andPolyline: coords)
        }
        
        return trips
        
    }
    
    public static func loadTimeFrameTrip2(fromJSON json: JSON) -> TimeFrameTrip? {

        let coords = json["polyline"]["features"].arrayValue.map { MapEntity(name: "line", location: CLLocation(latitude: $0["geometry"]["coordinates"][1].doubleValue, longitude: $0["geometry"]["coordinates"][0].doubleValue ))  }
        
        if json["cancelled"].exists() {
            Log.warning("\(json["stop"]["name"]) cancelled")
            return nil
        }
        
        let tl = generateTimeLine(forTrip: json)
        let locationBasedFeatures = getFeaturesWithDates(forFeatures: tl.line, andAnimationData: tl.animationData)
        
        return TimeFrameTrip(withDeparture: tl.departure, andName: tl.name, andPolyline: coords,andLocationMapping: locationBasedFeatures)  
       }
    
    //TODO for journeys / Mocking
    public static func loadTimeFrameTrip(fromJSON json: JSON) -> Array<TimeFrameTrip>? {
           
           let trips = json.arrayValue
               .filter({ $0["line"]["id"].stringValue != "bus-sev" })
               .filter({ $0["line"]["name"].stringValue != "Bus SEV" })
               .map { (json) -> TimeFrameTrip in
                   
                   let coords = json["polyline"]["features"].arrayValue.map { MapEntity(name: "line", location: CLLocation(latitude: $0["geometry"]["coordinates"][1].doubleValue, longitude: $0["geometry"]["coordinates"][0].doubleValue ))  }
                   
                let tl = generateTimeLine(forTrip: json)
                let locationBasedFeatures = getFeaturesWithDates(forFeatures: tl.line, andAnimationData: tl.animationData)
                   
                return TimeFrameTrip(withDeparture: tl.departure, andName: tl.name, andPolyline: coords,andLocationMapping: locationBasedFeatures)
           }
           
           return trips
           
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

