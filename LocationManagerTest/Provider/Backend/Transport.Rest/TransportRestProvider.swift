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
import PromisedFuture

class TransportRestProvider: TrainDataProviderProtocol {
   
    var delegate: TrainDataProviderDelegate? = nil

    var journeys: Array<Journey> = []

    typealias TripData = TimeFrameTrip
    
    func getAllTrips() -> Array<TimeFrameTrip> {
        return []
    }
     
    func update() {
        self.fetchDepartures(forStation: "8000049")
        .execute { (result) in
            switch result {
            case .success(let journeys):
                self.journeys = journeys
            case .failure(let error):
                Log.error("Error while fetching trips \(error.localizedDescription)")
            }
        }
    }
    
    public enum APIServiceError: Error {
        case apiError
        case invalidEndpoint
        case invalidResponse
        case noData
        case decodeError
    }
    
    private func fetchDepartures(forStation id: String) -> PromisedFuture.Future<Array<Journey>, Error> {
        
        let headers = HTTPHeaders([HTTPHeader(name: "X-Identifier", value: "de.f1ndus.iOS.train")])
        
        let now = Int(Date().addingTimeInterval(-2700).timeIntervalSince1970)
        //TODO time based on distance/time to station
        
        let parameters = [
            "departure" : String(now),
            "duration" : "60"
        ]
        
        return Future (operation: { completion in
            AF.request("https://2.db.transport.rest/stations/\(id)/departures", parameters: parameters, headers: headers ).responseData { (response) in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    let journeys = HafasParser.getJourneys(fromJSON: json)
                    completion(.success(journeys))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        })
        
    }
}
