//
//  MockTrainDataTimeFrameProvider.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 06.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import SwiftyJSON

class MockTrainDataTimeFrameProvider: TrainDataProviderProtocol {
   
    var delegate: TrainDataProviderDelegate? = nil

    typealias TripData = TimeFrameTrip
    
    let decoder = JSONDecoder()
      
    init() {
        decoder.dateDecodingStrategy = .formatted(getDateFormatter())
    }
       
    func getAllTrips() -> Array<TimeFrameTrip> {
        guard let trip = self.loadTrip() else {
                return []
        }
        return HafasParser.loadTimeFrameTrip(fromHafasTrips: [trip])
    }
    
    func update() {
        self.delegate?.onTripsUpdated()
    }
    
    func setDeleate(delegate: TrainDataProviderDelegate) {
        self.delegate = delegate
    }
    
    private func loadTrip() -> HafasTrip? {
        guard
            let filePath = Bundle(for: type(of: self)).path(forResource: "wfb_trip", ofType: ""),
            let trip = try? Data(contentsOf: URL(fileURLWithPath: filePath))
            else {
                return nil
        }
        do {
            return try decoder.decode(HafasTrip.self, from: trip)
        } catch {
            Log.error(error)
        }
        return nil
    }
}
