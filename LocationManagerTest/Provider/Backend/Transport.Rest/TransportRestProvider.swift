//
//  TransportRest.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 06.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import Combine

class TransportRestProvider: TrainDataProviderProtocol {
   
    var delegate: TrainDataProviderDelegate? = nil

    var journeys: Set<Journey> = []

    typealias TripData = TimeFrameTrip
    
    func getAllTrips() -> Array<TimeFrameTrip> {
        return []
    }
     
    func update() {
        
        //let combined = Publishers.Merge(fetchArrivals(forStation: "8000049"), fetchDepartures(forStation: "8000049"))
        fetchDepartures(forStation: "8000049")
        .merge(with: fetchArrivals(forStation: "8000049"))
        .collect()
        .map({ ( output : [Publishers.MergeMany<Future<Array<Journey>, AFError>>.Output]) -> Set<Journey> in
            Set(Array(output.joined()))
        })
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { (onComplete) in
                Log.info(onComplete)
            }) { (journeys) in
                self.journeys = journeys
        }
    }
    
    private func fetchDepartures(forStation id: String) -> Future<Array<Journey>, AFError> {
        
        let headers = HTTPHeaders([HTTPHeader(name: "X-Identifier", value: "de.f1ndus.iOS.train")])
        
        let now = Int(Date().addingTimeInterval(-2700).timeIntervalSince1970)
        //TODO time based on distance/time to station
        
        let parameters = [
            "departure" : String(now),
            "duration" : "60"
        ]
        
        return Future<Array<Journey>, AFError> { (completion) in
            AF.request("https://2.db.transport.rest/stations/\(id)/departures", parameters: parameters, headers: headers ).responseData { (response) in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    let journeys = HafasParser.getJourneys(fromJSON: json)
                    Log.info("Fetched \(journeys.count) departures")
                    Log.trace("\(json)")
                    completion(.success(journeys))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
    }
    
    private func fetchArrivals(forStation id: String) -> Future<Array<Journey>, AFError> {
        
        let headers = HTTPHeaders([HTTPHeader(name: "X-Identifier", value: "de.f1ndus.iOS.train")])
        
        let now = Int(Date().addingTimeInterval(2700).timeIntervalSince1970)
        //TODO time based on distance/time to station
        
        let parameters = [
            "departure" : String(now),
            "duration" : "60"
        ]
        
        return Future<Array<Journey>, AFError> { (completion) in
            AF.request("https://2.db.transport.rest/stations/\(id)/arrivals", parameters: parameters, headers: headers ).responseData { (response) in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    let journeys = HafasParser.getJourneys(fromJSON: json)
                    Log.info("Fetched \(journeys.count) departures")
                    Log.trace("\(json)")
                    completion(.success(journeys))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
    }
}
