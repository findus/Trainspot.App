//
//  HafasJourney.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 08.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

struct HafasJourney: Decodable {
    let tripId: String
    let stop: HafasStop
    let line: HafasLine
}

struct HafasStop: Decodable {
    let type: String
    let id: String
    let name: String
    let when: Date
    let departue: Date
    let arrival: Date
    
    let departurDdelay: Int
    let arrivalDelay: Int
    
    let location: HafasCoordinates
}

struct HafasLine: Decodable {
    let id:String
    let fahrtNr: String
    let name: String
    let cancelled: Bool?
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
    let lat: String
    let long: String
}

struct HafasPoint: Decodable {
    let coordinates: HafasCoordinates
}

struct HafasFeature: Decodable {
    let type: String
    let properties: HafasStop
    let geometry: HafasPoint
}
