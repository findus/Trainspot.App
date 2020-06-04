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
    
    func trainPosition() -> CLLocation? {
        
        // let currentTime = Date() disabled for debugging
        
        var dateComponents = DateComponents()
        dateComponents.year = 2020
        dateComponents.month = 6
        dateComponents.day = 4
        dateComponents.hour = 14
        dateComponents.minute = 59

        // Create date from components
        let userCalendar = Calendar.current // user calendar
        let currentTime = userCalendar.date(from: dateComponents)!
        
        let (e1, nextStop) = line.enumerated().filter({ $0.element is StopOver && ($0.element as! StopOver).arrival?.timeIntervalSince(currentTime) ?? -1 >= 0 }).first!
        let (e2, lastStop) = line.enumerated().filter({ $0.element is StopOver && ($0.element as! StopOver).departure?.timeIntervalSince(currentTime) ?? 1 <= 0 }).last!
        let timeNeededAtoB = (nextStop as! StopOver).arrival!.timeIntervalSince((lastStop as! StopOver).departure!)
        let timeSinceAtoNow = currentTime.timeIntervalSince((lastStop as! StopOver).departure!)
        
        let remaining = timeNeededAtoB - timeSinceAtoNow
        
        let percentageMissing = remaining / timeNeededAtoB
        
        let slice = line[e2...e1]
        let distance = zip(slice,slice.dropFirst()).map { (first, second) -> Double in
            let c1 = CLLocation(latitude: first.lat, longitude: first.lon)
            let c2 = CLLocation(latitude: second.lat, longitude: second.lon)
            return c1.distance(from: c2)
        }
        
        let sum = distance.reduce(0, +)
        
        let missingdistance = sum * percentageMissing
        
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
            return temploc
            
            
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
 
    func getAllTrips() -> Array<Trip> {
        return loadTrips() ?? []
    }
    
    private func getJourneys(fromJSON json: JSON) -> Array<Journey> {
        json.arrayValue
            .filter({ ["nationalExpress", "national", "regionalExp", "regional"].contains(where: $0["line"]["product"].stringValue.contains)  })
            .map { Journey(from_id: $0["stop"]["id"].stringValue, from: $0["stop"]["name"].stringValue, to: $0["direction"].stringValue, tripID: $0["tripId"].stringValue) }
    }
}

