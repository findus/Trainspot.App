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

class TransportRestProvider {
    
    let SERVER = "https://transport.russendis.co"
    
    let decoder = JSONDecoder()
   
    var delegate: TrainDataProviderDelegate? = nil

    var journeys: Set<Journey> = []
    var trips: Array<HafasTrip> = []

    typealias TripData = TimeFrameTrip
    
    init() {
        decoder.dateDecodingStrategy = .formatted(getDateFormatter())
    }
    
    func getAllTrips() -> Array<HafasTrip> {
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
            Set<HafasJourney>(Array(output.joined())).filter({ ["nationalExpress", "national", "regionalExp", "regional"].contains($0.line.product) })
        })
        .flatMap({ (journeys: Set<HafasJourney>) -> Future<Array<HafasTrip>, AFError> in
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
                self.trips = trips
               // self.delegate?.onTripsUpdated()
        }
    }
    
    private func generateTripFutures(fromJourneys journeys: Set<HafasJourney>) -> Array<Future<HafasTrip, AFError>> {
        return Array(journeys).map { (journey) -> Future<HafasTrip, AFError> in
            self.fetchTrip(forJourney: journey)
        }
    }
    
    private func fetch(trips fromFutures: Array<Future<HafasTrip, AFError>>) -> Future<Array<HafasTrip>, AFError> {
        return Future { (completion) in
            let _ = Publishers.MergeMany(fromFutures).collect().receive(on: RunLoop.current).sink(receiveCompletion: {(result) in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .finished:
                    Log.info(result)
                }
            }) { (trips: Array<HafasTrip>) in
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
            AF.request("\(self.SERVER)/stations/\(id)/departures", parameters: parameters, headers: headers ).responseDecodable(of: Array<HafasJourney>.self, decoder: self.decoder) { (response) in
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
            AF.request("\(self.SERVER)/stations/\(id)/arrivals", parameters: parameters, headers: headers ).responseDecodable(of: Array<HafasJourney>.self, decoder: self.decoder) { (response) in
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
    
    private func fetchTrip(forJourney journey: HafasJourney) -> Future<HafasTrip, AFError> {
         
         let headers = HTTPHeaders([HTTPHeader(name: "X-Identifier", value: "de.f1ndus.iOS.train")])
         
         let parameters = [
            "lineName" : journey.line.name,
            "polyline" : "true"
         ]
        
        let urlParameters = URLComponents(string: "\(SERVER)/trips/\(journey.tripId.replacingOccurrences(of: "|", with: "%7C"))")!
         
         return Future<HafasTrip, AFError> { (completion) in
            AF.request(urlParameters.url!, parameters: parameters, headers: headers ).responseDecodable(of: HafasTrip.self, decoder: self.decoder) { (response) in
                 switch response.result {
                 case .success(let value):
                     completion(.success(value))
                 case .failure(let error):
                    Log.debug(error)
                    completion(.failure(error))
                 }
             }
         }
         
     }
}
