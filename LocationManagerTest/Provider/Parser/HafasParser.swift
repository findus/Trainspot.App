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
    
    public static func generateTimeLine(forTrip trip: JSON) -> Timeline {
        let stops = trip["stopovers"].arrayValue
        let polyline = trip["polyline"]["features"].arrayValue
        
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        
        let date = dateFormatterGet.date(from: trip["departure"].stringValue)!
        
        let name = trip["line"]["name"].stringValue
        
        let line = polyline.map { (entry) -> Feature in
            
            let stopId = entry["properties"]["id"]
            
            let lat = entry["geometry"]["coordinates"][1].doubleValue
            let lon = entry["geometry"]["coordinates"][0].doubleValue
            
            if stopId.exists() {
                let stopOver = stops.filter({ $0["stop"]["id"] == stopId }).first!
                
                let departure = dateFormatterGet.date(from: stopOver["departure"].stringValue)
                let arrival =  dateFormatterGet.date(from: stopOver["arrival"].stringValue)
                
                let name = stopOver["stop"]["name"].stringValue
                
                return StopOver(name: name, coords: CLLocation(latitude: lat, longitude: lon) , arrival: arrival, departure: departure)
            } else {
                return Path(coords: CLLocation(latitude: lat, longitude: lon))
            }
        }
        
        let animationData = generateAnimationData(fromFeatures: line)
        let test = getFeaturesWithDates(forFeatures: line, andAnimationData: animationData)
        
        return Timeline(name: name, line: line, animationData: animationData ,departure: date)
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
            
            let time = (features[arrival] as! StopOver).arrival!.timeIntervalSince((features[departure] as! StopOver).departure!)
            
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
            .map { (json) -> JourneyTrip in
                
                let coords = json["polyline"]["features"].arrayValue.map { MapEntity(name: "line", location: CLLocation(latitude: $0["geometry"]["coordinates"][1].doubleValue, longitude: $0["geometry"]["coordinates"][0].doubleValue ))  }
                
                let tl = generateTimeLine(forTrip: json)
                
                return JourneyTrip(withDeparture: tl.departure, andName: tl.name, andTimeline: tl , andPolyline: coords)
        }
        
        return trips
        
    }
    
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
    
    private func getJourneys(fromJSON json: JSON) -> Array<Journey> {
        json.arrayValue
            .filter({ ["nationalExpress", "national", "regionalExp", "regional"].contains(where: $0["line"]["product"].stringValue.contains)  })
            .map { Journey(from_id: $0["stop"]["id"].stringValue, from: $0["stop"]["name"].stringValue, to: $0["direction"].stringValue, tripID: $0["tripId"].stringValue) }
    }

}

