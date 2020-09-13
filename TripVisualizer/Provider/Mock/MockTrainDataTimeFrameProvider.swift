//
//  MockTrainDataTimeFrameProvider.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 06.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import TripVisualizer

public class MockTrainDataTimeFrameProvider: TrainDataProviderProtocol {
    
    var tripFile: String
   
    var delegate: TrainDataProviderDelegate? = nil

    public typealias TripData = TimeFrameTrip
    
    let decoder = JSONDecoder()
      
    public init(withFile file: String) {
        decoder.dateDecodingStrategy = .formatted(getDateFormatter())
        tripFile = file
    }
       
    public func getAllTrips() -> Array<TimeFrameTrip> {
        guard let trip = self.loadTrip() else {
                return []
        }
        return HafasParser.loadTimeFrameTrip(fromHafasTrips: [trip])
    }
    
    public func update() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.delegate?.onTripsUpdated(result: .success)
        }
    }
    
    public func setDeleate(delegate: TrainDataProviderDelegate) {
        self.delegate = delegate
    }
    
    public func setTrip(withName name: String) {
        self.tripFile = name
    }
    
    private func loadTrip() -> HafasTrip? {
        guard
            let filePath = Bundle(for: type(of: self)).path(forResource: self.tripFile, ofType: ""),
            let trip = try? Data(contentsOf: URL(fileURLWithPath: filePath))
            else {
                return nil
        }
        do {
            return try decoder.decode(HafasTrip.self, from: trip)
        } catch {
            print(error)
        }
        return nil
    }
}
