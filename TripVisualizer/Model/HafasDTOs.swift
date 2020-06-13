//
//  HafasJourney.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 08.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

struct HafasJourney: Decodable, Hashable {
    let tripId: String
    let stop: HafasStop
    let line: HafasLine
    let when: String?
    
    static func == (lhs: HafasJourney, rhs: HafasJourney) -> Bool {
        lhs.tripId == rhs.tripId
    }
    
    func hash(into hasher: inout Hasher) {
        return hasher.combine(self.tripId)
    }
}

struct HafasStop: Decodable {
    let type: String
    let id: String
    let name: String
    
    let location: HafasStopCoordinate
}

struct HafasLine: Decodable {
    let id:String
    let fahrtNr: String
    let name: String
    let cancelled: Bool?
    let product: String
}

struct HafasStopOver: Decodable {
    let stop :HafasStop
    let departure: Date?
    let arrival: Date?
    
//    let departureDelay: Int?
//    let arrivalDelay: Int?
}


public struct HafasTrip: Decodable {
    let id: String
    let origin: HafasStop
    let destination: HafasStop
    let departure: Date?
    let arrival: Date?
    let arrivalDelay: Int?
    let polyline: HafasFeatureCollection?
    let line: HafasLine
   //let direction: String
    let stopovers: Array<HafasStopOver>
}

struct HafasFeatureCollection: Decodable {
    let features: Array<HafasFeature>
}

struct HafasStopCoordinate: Decodable {
    var latitude: Double
    var longitude: Double
}

struct HafasPoint: Decodable {
    let type: String
    let coordinates: Array<Double>
}

public class HafasFeature: Decodable {
    let type: String
    let properties: HafasStop?
    let geometry: HafasPoint
    
    func isStopOver() -> Bool {
        return self.properties != nil
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, properties, geometry
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(String.self, forKey: .type)
        properties = try? values.decode(HafasStop.self, forKey: .properties)
        geometry = try values.decode(HafasPoint.self, forKey: .geometry)
    }
}
