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

    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet var statusView: StatusView!
    
    var mapViewController: MapViewController?
    let manager = TrainLocationProxy.shared
    var tripIdToUpdateLocation: String?
    
    var tripTimeFrameLocationController = TrainLocationTripByTimeFrameController()
    
    let tripProvider = MockTrainDataJourneyProvider.init()
    
    var lastLocation: CLLocation? {
        didSet {
            self.calcBearing()
        }
    }
    
    var pinnedLocation: CLLocation? {
        didSet {
            self.calcBearing()
            
            if self.pinnedLocation != nil {
                self.imageView.isHidden = false
            } else {
                self.imageView.isHidden = true
            }
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
     
    private func calcBearing() {
        let angle = self.computeNewAngle(with: CGFloat(self.heading ?? 0))
        self.imageView.transform = CGAffineTransform(rotationAngle: angle)
    }
    
    func computeNewAngle(with newAngle: CGFloat) -> CGFloat {
        let origHeading = self.pinnedLocationBearing - newAngle.toRadians
        return origHeading
    }
    
    @IBAction func onUpdateButtonPressed(_ sender: UIButton) {
        tripTimeFrameLocationController.fetchServer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.statusView.startTimer()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        self.mapViewController?.delegate = self
        self.manager.delegate?.append(self)
        
        
        UserLocationController.shared.register(delegate: self)
        
        // Start and append different controller instances
        let radarLocationController = TrainLocationRadarController()
        let tripLocationController = TrainLocationTripAnimationTimeController()
        tripTimeFrameLocationController = TrainLocationTripByTimeFrameController()
        
        //tripLocationController.setDataProvider(withProvider: TripProvider(MockTrainDataJourneyProvider()))
        
        tripTimeFrameLocationController.setDataProvider(withProvider: TripProvider(NetworkTrainDataTimeFrameProvider()))
        
        //tripTimeFrameLocationController.setDataProvider(withProvider: TripProvider(TransportRestProvider()))
      
        // self.manager.register(controller: radarLocationController)
        //self.manager.register(controller: tripLocationController)
        self.manager.register(controller: tripTimeFrameLocationController)
        
        tripTimeFrameLocationController.fetchServer()
        
        self.imageView.isHidden = true
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
        self.tripTimeFrameLocationController.setCurrentLocation(location: currentLocation)
    }

}

extension ViewController: MapViewControllerDelegate {
    func userPressedAt(location: CLLocation) {
//        self.mapViewController?.removeAllEntries()
//        self.pinnedLocation = location
//        self.mapViewController?.addEntry(entry: MapEntity(name: "test", location: location))

    }
}

extension ViewController: TrainLocationDelegate {
    var id: String {
        return "viewcontroller"
    }
    
    func removeTripFromMap(forTrip trip: Trip) {
        self.mapViewController?.deleteEntry(withName: trip.tripId, andLabel: trip.name)
    }
    
    func drawPolyLine(forTrip: Trip) {
        self.mapViewController?.drawLine(entries: forTrip.polyline)
    }
    
    func trainPositionUpdated(forTrip trip: Trip, withData data: TripData, withDuration duration: Double) {
        
        if trip.tripId == self.tripIdToUpdateLocation {
            
            self.setStatusView(withTrip: trip, andData: data)
            
            UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: {
                // Update annotation coordinate to be the destination coordinate
                self.pinnedLocation = data.location
            }, completion: nil)
        }
        
        guard let location = data.location?.coordinate else {
            return
        }
        
        self.mapViewController?.updateTrainLocation(forId: trip.tripId, withLabel: trip.name, toLocation: location, withDuration: duration)
        
    }
}

extension ViewController {
    
    private func setStatusView(withTrip trip: Trip, andData data: TripData) {        
        self.statusView.setStatus(forTrip: trip, andData: data)
    }
}
