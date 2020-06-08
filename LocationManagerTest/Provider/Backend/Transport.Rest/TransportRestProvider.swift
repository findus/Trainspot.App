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
    
    let decoder = JSONDecoder()
   
    var delegate: TrainDataProviderDelegate? = nil

    var journeys: Set<Journey> = []
    var trips: Array<TimeFrameTrip> = []

    typealias TripData = TimeFrameTrip
    
    init() {
        decoder.dateDecodingStrategy = .formatted(getDateFormatter())
    }
    
    func getAllTrips() -> Array<TimeFrameTrip> {
        return trips
    }
    
    func setDeleate(delegate: TrainDataProviderDelegate) {
        self.delegate = delegate
    }
     
    func update() {
        
        let _ = fetchDepartures(forStation: "8000049")
        .merge(with: fetchArrivals(forStation: "8000049"))
        .collect()
        .map({ ( output : [Publishers.MergeMany<Future<Array<HafasJourney>, AFError>>.Output]) -> Set<HafasJourney> in
            Set<HafasJourney>(Array(output.joined()))
        })
        .flatMap({ (journeys: Set<HafasJourney>) -> Future<Array<JSON>, AFError> in
                let futures = self.generateTripFutures(fromJourneys: journeys)
                return self.fetch(trips: futures)
        })
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { (result) in
            switch result {
            case .failure(let error):
                Log.error(error)
            case .finished:
                Log.info(result)
            }
            }) { (trips) in
                let trips = trips.compactMap({ HafasParser.loadTimeFrameTrip2(fromJSON: $0) })
                self.trips = trips
                self.delegate?.onTripsUpdated()
        }
    }
    
    private func generateTripFutures(fromJourneys journeys: Set<HafasJourney>) -> Array<Future<JSON, AFError>> {
        return Array(journeys).map { (journey) -> Future<JSON, AFError> in
            self.fetchTrip(forJourney: journey)
        }
    }
    
    private func fetch(trips fromFutures: Array<Future<JSON, AFError>>) -> Future<Array<JSON>, AFError> {
        return Future { (completion) in
            let _ = Publishers.MergeMany(fromFutures).collect().receive(on: RunLoop.current).sink(receiveCompletion: {(result) in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .finished:
                    Log.info(result)
                }
            }) { (trips: Array<JSON>) in
                completion(.success(trips))
            }
        }
    }
    
    
    // MARK: - Network code
    
    private func fetchDepartures(forStation id: String) -> Future<Array<HafasJourney>, AFError> {
        
        let headers = HTTPHeaders([HTTPHeader(name: "X-Identifier", value: "de.f1ndus.iOS.train")])
        
        let now = Int(Date().addingTimeInterval(-2700).timeIntervalSince1970)
        //TODO time based on distance/time to station
        
        let parameters = [
            "departure" : String(now),
            "duration" : "60"
        ]
        
        return Future<Array<HafasJourney>, AFError> { (completion) in
            AF.request("https://2.db.transport.rest/stations/\(id)/departures", parameters: parameters, headers: headers ).responseDecodable(of: Array<HafasJourney>.self, decoder: self.decoder) { (response) in
                switch response.result {
                case .success(let journeys):
                    Log.info("Fetched \(journeys.count) departures")
                    Log.trace("\(journeys)")
                    completion(.success(journeys))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
    }
    
    private func fetchArrivals(forStation id: String) -> Future<Array<HafasJourney>, AFError> {
        
        let headers = HTTPHeaders([HTTPHeader(name: "X-Identifier", value: "de.f1ndus.iOS.train")])
        
        let now = Int(Date().addingTimeInterval(2700).timeIntervalSince1970)
        //TODO time based on distance/time to station
        
        let parameters = [
            "departure" : String(now),
            "duration" : "60"
        ]
        
        return Future<Array<HafasJourney>, AFError> { (completion) in
            AF.request("https://2.db.transport.rest/stations/\(id)/arrivals", parameters: parameters, headers: headers ).responseDecodable(of: Array<HafasJourney>.self, decoder: self.decoder) { (response) in
                switch response.result {
                case .success(let journeys):
                    Log.info("Fetched \(journeys.count) departures")
                    Log.trace("\(journeys)")
                    completion(.success(journeys))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
    }
    
    private func fetchTrip(forJourney journey: HafasJourney) -> Future<JSON, AFError> {
         
         let headers = HTTPHeaders([HTTPHeader(name: "X-Identifier", value: "de.f1ndus.iOS.train")])
         
         let parameters = [
            "lineName" : journey.line.name,
            "polyline" : "true"
         ]
        
        let urlParameters = URLComponents(string: "https://2.db.transport.rest/trips/\(journey.tripId.replacingOccurrences(of: "|", with: "%7C"))")!
         
         return Future<JSON, AFError> { (completion) in
            AF.request(urlParameters.url!, parameters: parameters, headers: headers ).responseData { (response) in
                 switch response.result {
                 case .success(let value):
                     let json = JSON(value)
                     completion(.success(json))
                 case .failure(let error):
                    Log.debug(error)
                    completion(.failure(error))
                 }
             }
         }
         
     }
}
