//
//  TransportRest.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 06.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import SwiftyJSON

class TransportRestProvider: TrainDataProviderProtocol {
   
    var delegate: TrainDataProviderDelegate? = nil

    var journeys: JSON? = nil

    typealias TripData = TimeFrameTrip
    
    func getAllTrips() -> Array<TimeFrameTrip> {
        return []
    }
     
    func update() {
        self.downloadJourneys(forStation: "8000049")
    }
    
    public enum APIServiceError: Error {
        case apiError
        case invalidEndpoint
        case invalidResponse
        case noData
        case decodeError
    }
        
    private func downloadJourneys(forStation id: String) -> Void {
        
        let now = Int(Date().addingTimeInterval(-2700).timeIntervalSince1970)
        
        //TODO time based on distance/time to station
        
        var urlComponents = NSURLComponents(string: "https://2.db.transport.rest/stations/\(id)/departures")!

        urlComponents.queryItems = [
          URLQueryItem(name: "departures", value: String(now)),
          URLQueryItem(name: "duration", value: "60")
        ]
        
        guard let url = urlComponents.url else {
            Log.error("Could not parse url")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("de.f1ndus.trainspotTest", forHTTPHeaderField: "X-Identifier")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
                let json = JSON(data)
                self.journeys = json
            }
        }

        task.resume()
    }
}

extension URLSession {
    func dataTask(with url: URL, result: @escaping (Result<(URLResponse, Data), Error>) -> Void) -> URLSessionDataTask {
        return dataTask(with: url) { (data, response, error) in
            if let error = error {
                result(.failure(error))
                return
            }
            
            guard let response = response, let data = data else {
                let error = NSError(domain: "error", code: 0, userInfo: nil)
                result(.failure(error))
                return
            }
            result(.success((response, data)))
        }
    }
}
