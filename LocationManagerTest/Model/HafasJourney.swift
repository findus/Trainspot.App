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
    let when: Date
    
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
}

struct HafasStopOver: Decodable {
    let stop :HafasStop
    let departure: Date
    let arrival: Date
    
    let departurDdelay: Int
    let arrivalDelay: Int
}


struct HafasTrip: Decodable {
    let id: String
    let origin: HafasStop
    let destination: HafasStop
    let departure: Date?
    let arrival: Date?
    let arrivalDelay: Int
    let polyline: FeatureCollection
    let line: HafasLine
    let direction: String
    let stopovers: Array<HafasStop>
}

struct FeatureCollection: Decodable {
    let features: Array<HafasFeature>
}

struct HafasCoordinates: Decodable {
    var lat: Double
    var lon: Double
    
    private enum CodingKeys: String, CodingKey {
        case lat = "0", lon = "1"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lat = try container.decode(Double.self, forKey: .lat)
        lon = try container.decode(Double.self, forKey: .lon)
    }
}

struct HafasStopCoordinate: Decodable {
    var latitude: Double
    var longitude: Double
}

struct HafasPoint: Decodable {
    let coordinates: HafasCoordinates
}

struct HafasFeature: Decodable {
    let type: String
    let properties: HafasStop
    let geometry: HafasPoint
}
