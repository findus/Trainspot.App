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

protocol Feature {
    
}

struct Path: Feature {
    var lat: Double
    var lon: Double
}

struct StopOver: Feature {
    
    var lat: Double
    var lon: Double
    var name: String
    
    var arrival: Date
    var departure: Date
}

struct Timeline {
    var name: String
    var line: Array<Feature>
    var departure: Date
}

class MockTrainDataJourneyProvider: TrainDataProviderProtocol {

    
    func generateTimeLine(forTrip trip: JSON) -> Timeline {
        let stops = trip["stopovers"].arrayValue
        let polyline = trip["polyline"]["features"].arrayValue
        
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

        let date = dateFormatterGet.date(from: trip["departure"].stringValue)!
                
        let name = trip["line"]["name"].stringValue
        
        let line = polyline.map { (entry) -> Feature in
                    
            let stopId = entry["properties"]["id"]
            
            let lat = entry["geometry"]["coordinates"][1].doubleValue
            let lon = entry["geometry"]["coordinates"][0].doubleValue
            
            if stopId.exists() {
                let stopOver = stops.filter({ $0["stop"]["id"] == stopId }).first!
                
                let departure = dateFormatterGet.date(from: stopOver["departure"].stringValue)!
                let arrival =  dateFormatterGet.date(from: stopOver["arrival"].stringValue)!
                
                let name = stopOver["stop"]["name"].stringValue
                
                return StopOver(lat: lat, lon: lon, name: name, arrival: arrival, departure: departure)
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

