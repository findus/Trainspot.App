//
//  MockTrainDataJourneyProvider.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 04.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreLocation
import simd

protocol Feature {
    var lat: Double { get set }
    var lon: Double { get set }
}

struct Path: Feature {
    var lat: Double
    var lon: Double
    
    //animation data
    var duration: Int?
    var lastBeforeStop: Bool = false
}

struct StopOver: Feature {

    var name: String
    
    var lat: Double
    var lon: Double
    var arrival: Date?
    var departure: Date?
}



struct Timeline {
    var name: String
    var line: Array<Feature>
    var departure: Date
    
    
    /**
     Tries to find the exact train position on the polyine, returns the approximate position, the end of the current line the train is on, and the duration how long it would take to reach it
     */
    func trainPosition() -> (current:CLLocation, nextOnMap: CLLocation, duration: Int)? {
        
        // let currentTime = Date() disabled for debugging
        
        var dateComponents = DateComponents()
        dateComponents.year = 2020
        dateComponents.month = 6
        dateComponents.day = 4
        dateComponents.hour = 15
        dateComponents.minute = 00

        // Create date from components
        let userCalendar = Calendar.current // user calendar
        let currentTime = userCalendar.date(from: dateComponents)!
        
        // Finds the next Stop for the current train
        let (e1, nextStop) = line.enumerated().filter({ $0.element is StopOver && ($0.element as! StopOver).arrival?.timeIntervalSince(currentTime) ?? -1 >= 0 }).first!
        // Finds the last Stop for the current train
        let (e2, lastStop) = line.enumerated().filter({ $0.element is StopOver && ($0.element as! StopOver).departure?.timeIntervalSince(currentTime) ?? 1 <= 0 }).last!
        
        // Calculates the time, the Train needs to travel between the last and the next stop
        let timeNeededAtoB = (nextStop as! StopOver).arrival!.timeIntervalSince((lastStop as! StopOver).departure!)
        
        // Calculates the time the train is already moving since the last stop
        let timeSinceAtoNow = currentTime.timeIntervalSince((lastStop as! StopOver).departure!)
        
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
        for (first, second) in zip(slice,slice.dropFirst()).reversed() {
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
            return (temploc,c1,10)
            
            
//            let vec = SIMD2(x: c1.coordinate.latitude - c2.coordinate.latitude, y: c1.coordinate.longitude - c2.coordinate.longitude)
//            let normvec = simd_normalize(vec)
//            let distance = simd_distance(simd_double8(normvec.x), simd_double8(normvec.y))
//            let distance1 = simd_distance(simd_double8(vec.x), simd_double8(vec.y))
//            print(normvec)
        }
        
        print(missingdistance)
        return nil
    }
    
    
}

class MockTrainDataJourneyProvider: TrainDataProviderProtocol {

    typealias TripData = JourneyTrip
    
    func getAllTrips() -> Array<JourneyTrip> {
        return self.loadTrips() ?? []
    }
    
    func generateTimeLine(forTrip trip: JSON) -> Timeline {
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
                
                return StopOver(name: name, lat: lat, lon: lon, arrival: arrival, departure: departure)
            } else {
                return Path(lat: lat, lon: lon)
            }
        }
        
        
        return Timeline(name: name, line: line, departure: date)
    }
    
    
    
    private func loadTrips() -> Array<JourneyTrip>? {
        guard
            let filePath = Bundle(for: type(of: self)).path(forResource: "trip_test", ofType: ""),
            let wf_trip_data = NSData(contentsOfFile: filePath) else {
                return nil
        }
        
        let json = try! JSON(data: wf_trip_data as Data)
        

        let trips = json.arrayValue
            .filter({ $0["line"]["id"].stringValue != "bus-sev" })
            .filter({ $0["line"]["name"].stringValue != "Bus SEV" })
            .map { (json) -> JourneyTrip in
                
                let coords = json["polyline"]["features"].arrayValue.map { MapEntity(name: "line", location: CLLocation(latitude: $0["geometry"]["coordinates"][1].doubleValue, longitude: $0["geometry"]["coordinates"][0].doubleValue ))  }
                
                let tl = generateTimeLine(forTrip: json)
                
                return JourneyTrip(withFetchTime: tl.departure, andName: tl.name, andTimeline: tl , andPolyline: coords)
        }
        
        return trips

    }
 
    private func getJourneys(fromJSON json: JSON) -> Array<Journey> {
        json.arrayValue
            .filter({ ["nationalExpress", "national", "regionalExp", "regional"].contains(where: $0["line"]["product"].stringValue.contains)  })
            .map { Journey(from_id: $0["stop"]["id"].stringValue, from: $0["stop"]["name"].stringValue, to: $0["direction"].stringValue, tripID: $0["tripId"].stringValue) }
    }
}

