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

struct Section {
    var distance: Double
    var time: TimeInterval
    var segemnts: Array<CLLocation>
}

struct Timeline {
    var name: String
    var line: Array<Feature>
    var departure: Date
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

