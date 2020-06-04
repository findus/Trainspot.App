//
//  ViewController.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import SwiftyJSON

class ViewController: UIViewController, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()
    var mapViewController: MapViewController?
    let manager = TrainLocationProxy.shared
    
    let tripProvider = MockTrainDataJourneyProvider.init()
    
    var lastLocation: CLLocation? {
        didSet {
            self.calcBearing()
        }
    }
    
    var pinnedLocation: CLLocation? {
        didSet {
            self.calcBearing()
        }
    }
    
    var heading: CGFloat? {
        didSet {
            self.calcBearing()
        }
    }
    
    var pinnedLocationBearing: CGFloat {
        return lastLocation?.bearingToLocationRadian(self.pinnedLocation ?? CLLocation()) ?? 0
    }
    
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    private func calcBearing() {
        let angle = self.computeNewAngle(with: CGFloat(self.heading ?? 0))
        self.imageView.transform = CGAffineTransform(rotationAngle: angle)
    }
    
    func computeNewAngle(with newAngle: CGFloat) -> CGFloat {
        let origHeading = self.pinnedLocationBearing - newAngle.toRadians
        return origHeading
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
        
        self.mapViewController?.delegate = self
        self.manager.delegate = self
        
        // Start and append different controller instances
        let radarLocationController = TrainLocationRadarController()
        let tripLocationController = TrainLocationTripController()
        self.manager.register(controller: radarLocationController)
        self.manager.register(controller: tripLocationController)

        
//        let trips = tripProvider.getAllTrips()
//        
//        trips.forEach { (trip) in
//            
//            self.mapViewController?.drawLine(entries: trip.line)
//            let mapEntity = MapEntity(name: trip.name, location: trip.line.first!.location)
//            self.mapViewController?.addEntry(entry: mapEntity)
//            _ = self.manager.register(trip: trip)
//        }

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc1 as MapViewController:
            self.mapViewController = vc1
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        UIView.animate(withDuration: 0.5) {
            self.heading = CGFloat(newHeading.trueHeading)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        lastLocation = currentLocation
    }

}

extension ViewController: MapViewControllerDelegate {
    func userPressedAt(location: CLLocation) {
        self.mapViewController?.removeAllEntries()
        self.pinnedLocation = location
        self.mapViewController?.addEntry(entry: MapEntity(name: "test", location: location))

    }
}

extension ViewController: TrainLocationDelegate {
    func drawPolyLine(forTrip: Trip) {
        self.mapViewController?.drawLine(entries: forTrip.line)
    }
    
    func trainPositionUpdated(forTrip trip: Trip, toPosition: Int, withDuration duration: Double) {
        self.mapViewController?.updateTrainLocation(forId: trip.name, toLocation: trip.line[toPosition].location.coordinate, withDuration: duration)
        self.pinnedLocation = trip.line[toPosition].location
        if let lastLocation = self.lastLocation  {
            print("Shortest Distance to Track: \(trip.shorttestDistanceToTrack(forUserLocation: lastLocation))")
            print("Is arriving: \(!trip.isParting(forUserLocation: lastLocation))")

        }
    }
}


