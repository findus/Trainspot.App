//
//  TransportRest.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 06.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import Alamofire
import Combine

class TransportRestProvider<PT: Trip> {
    
    let SERVER = "https://transport.f1ndus.de"
    
    let decoder = JSONDecoder()
   
    var delegate: TrainDataProviderDelegate? = nil

    var journeys: Set<Journey> = []
    var trips: Set<HafasTrip> = []

    var stream: AnyCancellable? = nil
    
    init() {
        decoder.dateDecodingStrategy = .formatted(getDateFormatter())
    }
    
    func getAllTrips() -> Set<HafasTrip> {
        return trips
    }
    
    func setDeleate(delegate: TrainDataProviderDelegate) {
        self.delegate = delegate
    }
    
    private func streamOfJourneys(output: [Publishers.Merge<AnyPublisher<Array<HafasJourney>, AFError>,AnyPublisher<Array<HafasJourney>, AFError>>.Output]) -> Set<HafasJourney> {
        return Set(output.flatMap({$0})).filter({ ["nationalExp","nationalExpress", "national", "regionalExp", "regional"].contains($0.line.product) })
    }
    
    private func fetchTripsFromJourneyArray(withJourneys journeys: Set<HafasJourney>) -> AnyPublisher<Array<HafasTrip>, AFError> {
        Log.info("Fetching Trips for \(journeys.count) journeys")
        return Publishers.Sequence(sequence:  self.generateTripPublishers(fromJourneys: journeys)).flatMap { $0 }.collect().eraseToAnyPublisher()
    }
    
    private func generateTripPublishers(fromJourneys journeys: Set<HafasJourney>) -> Array<AnyPublisher<HafasTrip, AFError>> {
        return  Array(journeys).map( { (journey) -> AnyPublisher<HafasTrip, AFError> in
            self.fetchTrip(forJourney: journey)
        })
    }
    
    func updateSelectedTrips(trips: Array<PT>) {
        self.stream?.cancel()
        
        let publishers: Array<AnyPublisher<HafasTrip, AFError>> = trips.map({ self.fetchTrip(forTripID: $0.tripId).eraseToAnyPublisher() })
        
        let cancelable = Publishers.Sequence(sequence: publishers)
            .flatMap { $0 }
            .collect()
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main).sink(receiveCompletion: { (result) in
                switch result {
                case .failure(let error):
                    Log.error(error)
                    self.delegate?.onTripsUpdated(result: .error(error.errorDescription ?? ""))
                case .finished:
                    Log.info(result)
                }
            }) { (refreshedTrips) in
                self.trips = Set(refreshedTrips).union(self.trips)
                self.delegate?.onTripsUpdated(result: .success)
        }
        
        self.stream = cancelable
    }
         
    func update() {
        let station = UserPrefs.getSelectedStation()
        let departures = fetchDepartures(forStation: station.ibnr)
        let arrivals = fetchArrivals(forStation: station.ibnr)
        
        // Cancel old request
        self.stream?.cancel()
        
        let cancellable = Publishers.Merge(departures, arrivals)
            .collect()
            .map(streamOfJourneys)
            .flatMap(fetchTripsFromJourneyArray)
            .receive(on: RunLoop.main).sink(receiveCompletion: { (result) in
                switch result {
                case .failure(let error):
                    Log.error(error)
                    self.delegate?.onTripsUpdated(result: .error(error.errorDescription ?? ""))
                case .finished:
                    Log.info(result)
                }
            }) { (trips) in
                self.trips = Set(trips)
                self.delegate?.onTripsUpdated(result: .success)
        }
        
        self.stream = cancellable
    }
    

    // MARK: - Network code
    
    private func fetchDepartures(forStation id: String) -> AnyPublisher<Array<HafasJourney>, AFError> {
        
        /**
        Viewer                         Station
          |____10Minutes_____|
         Now                           10 Minutes earlier
         */
        
        let headers = HTTPHeaders([HTTPHeader(name: "X-Identifier", value: "de.f1ndus.iOS.train")])
        let offset = UserPrefs.getTimeOffset()*60
        let departureDate = Int(Date().addingTimeInterval(-TimeInterval(offset)).timeIntervalSince1970)
        Log.info("Fetching departures that will pass viewer at \(departureDate) up to \(Date().addingTimeInterval(60*45))")
        //TODO time based on distance/time to station
        let parameters = [
            "when" : String(departureDate),
            "duration" : "45"
        ]
        
        return AF.request("\(self.SERVER)/stations/\(id)/departures", parameters: parameters, headers: headers ).publishDecodable(type: Array<HafasJourney>.self,  decoder: self.decoder).value().receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    private func fetchArrivals(forStation id: String) -> AnyPublisher<Array<HafasJourney>, AFError> {
        
        let headers = HTTPHeaders([HTTPHeader(name: "X-Identifier", value: "de.f1ndus.iOS.train")])
        let offset = UserPrefs.getTimeOffset()*60
        let arrivalDate = Int(Date().addingTimeInterval(TimeInterval(offset)).timeIntervalSince1970)
        Log.info("Fetching arrivals at \(arrivalDate) to \(Date().addingTimeInterval(60*45))")
        //TODO time based on distance/time to station
        
        let parameters = [
            "when" : String(arrivalDate),
            "duration" : "45"
        ]
        
        return AF.request("\(self.SERVER)/stations/\(id)/arrivals", parameters: parameters, headers: headers ).publishDecodable(type: Array<HafasJourney>.self, decoder: self.decoder).value().receive(on: DispatchQueue.main).eraseToAnyPublisher()
        
    }
    
    private func fetchTrip(forTripID id: String) -> AnyPublisher<HafasTrip, AFError> {
        let headers = HTTPHeaders([HTTPHeader(name: "X-Identifier", value: "de.f1ndus.iOS.train")])
        
        let parameters = [
            "lineName" : id,
            "polyline" : "true"
        ]
        
        let urlParameters = URLComponents(string: "\(SERVER)/trips/\(id.replacingOccurrences(of: "|", with: "%7C"))")!
        
        Log.debug("Url Request for Trip:", "\(urlParameters)?lineName=\(parameters["lineName"]!)")
        
        let request = AF.request(urlParameters.url!, parameters: parameters, headers: headers)
        return request.publishDecodable(type: HafasTrip.self, decoder: self.decoder).value().receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    private func fetchTrip(forJourney journey: HafasJourney) ->  AnyPublisher<HafasTrip, AFError> {
        return self.fetchTrip(forTripID: journey.tripId)
    }
}

