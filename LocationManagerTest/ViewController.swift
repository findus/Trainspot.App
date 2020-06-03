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
    let manager =  TrainLocationController.shared
    
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
        
        self.manager.delegate = self
        
        self.mapViewController?.delegate = self
        
        guard
            let filePath = Bundle(for: type(of: self)).path(forResource: "hafas_test_json", ofType: "json"),
            let data = NSData(contentsOfFile: filePath) else {
                return
        }
        
        let json = try! JSON(data: data as Data)
        let coords = json[0]["polyline"]["features"].arrayValue.map { MapEntity(name: "line", location: CLLocation(latitude: $0["geometry"]["coordinates"][1].doubleValue, longitude: $0["geometry"]["coordinates"][0].doubleValue ))  }
        let framecount = json[0]["frames"].arrayValue.count
        print("Frames  ", framecount)
        
        let polylinecount = json[0]["polyline"]["features"].arrayValue.count
        print("Polyline", polylinecount)
                
        self.mapViewController?.drawLine(entries: coords)
        
        
        let testJourney = Journey(withFetchTime: Date(), andName: json[0]["line"]["name"].stringValue, andLines: coords)
        
        let mapEntity = MapEntity(name: testJourney.name, location: testJourney.line.first!.location)
        
        self.mapViewController?.addEntry(entry: mapEntity)
        
        _ = self.manager.register(journey: testJourney)
    
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
    func trainPositionUpdated(forJourney journey: Journey, toPosition: Int, withDuration duration: Double) {
        self.mapViewController?.updateTrainLocation(forId: journey.name, toLocation: journey.line[toPosition].location.coordinate, withDuration: duration)
        self.pinnedLocation = journey.line[toPosition].location
        if let lastLocation = self.lastLocation  {
            print("Shortest Distance to Track: \(journey.shorttestDistanceToTrack(forUserLocation: lastLocation))")
        }
    }
}


