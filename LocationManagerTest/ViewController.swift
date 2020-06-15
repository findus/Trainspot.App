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
import TripVisualizer

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet var statusView: StatusView!
    @IBOutlet weak var loadingIndicatorHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomView: UIVisualEffectView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activiyIndicatorWrapper: UIView!
    
    // Status View Cache values
    var initialConstraintValue = CGFloat(0)
    var triggeredUpdate: Bool = false
    var isStillPulling = false
    
    let generator = UINotificationFeedbackGenerator()
    
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
 
        self.manager.delegate?.append(self)
        self.imageView.isHidden = true

        UserLocationController.shared.register(delegate: self)
         
        #if MOCK
        var components = DateComponents()
        components.second = 00
        components.hour = 16
        components.minute = 20
        components.day = 12
        components.month = 6
        components.year = 2020
        let date = Calendar.current.date(from: components)
        let traveler = TimeTraveler()
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            traveler.travel(by: 1)
        }
        traveler.date = date!
        tripTimeFrameLocationController = TrainLocationTripByTimeFrameController(dateGenerator: traveler.generateDate)
        tripTimeFrameLocationController.setDataProvider(withProvider: TripProvider(MockTrainDataTimeFrameProvider()))
        #else
        tripTimeFrameLocationController.setDataProvider(withProvider: TripProvider(NetworkTrainDataTimeFrameProvider()))
        #endif

        self.manager.register(controller: tripTimeFrameLocationController)
                
        self.statusView.startTimer()
        self.bottomView.layer.shadowOpacity = 0.7
        self.bottomView.layer.shadowOffset = CGSize(width: 3, height: 3)
        self.bottomView.layer.shadowRadius = 15.0
        self.bottomView.layer.shadowColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        
        // Pan reload gesture
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.dragged(gesture:)))
        
        self.bottomView.addGestureRecognizer(gesture)
        gesture.delegate = self
        self.loadingIndicator.isHidden = true
        self.loadingIndicatorHeightConstraint.constant = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.tripTimeFrameLocationController.fetchServer()
        }
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

extension ViewController: UIGestureRecognizerDelegate {
    
    
    @objc func dragged(gesture: UIPanGestureRecognizer) {
        
        let transform = gesture.translation(in: self.bottomView)
        
        if gesture.state == .began {
            initialConstraintValue = self.loadingIndicatorHeightConstraint.constant
        }
        
        if gesture.state == .ended {
            UIView.animate(withDuration: 0.25) {
                self.loadingIndicatorHeightConstraint.constant = self.triggeredUpdate ? 40 : 0
                self.view.layoutIfNeeded()
                self.isStillPulling = false
            }
            
        } else {
            if abs(transform.y) >= 200 && !triggeredUpdate && !isStillPulling {
                triggeredUpdate = true
                self.isStillPulling = true
                self.loadingIndicator.isHidden = false
                tripTimeFrameLocationController.fetchServer()
            }
            // Just a fance curve to slowly slow down animation speed while panning
            self.loadingIndicatorHeightConstraint.constant = transform.y > 0 ? 0: 9*(pow(abs(transform.y), 0.5)) + initialConstraintValue
        }
       
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
    
    //  Update
    
    public func onUpdateStarted() {
        self.loadingIndicator.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.loadingIndicatorHeightConstraint.constant = 40
            self.view.layoutIfNeeded()
            self.generator.notificationOccurred(.success)
        }
    }
    
    public func onUpdateEnded() {
        self.triggeredUpdate = false
        self.loadingIndicator.isHidden = true
        generator.notificationOccurred(.success)
        self.activiyIndicatorWrapper.backgroundColor = #colorLiteral(red: 0.1996439938, green: 0.690910533, blue: 0.4016630921, alpha: 0.759765625)
        
        UIView.animate(withDuration: 0.25, animations: {
            self.loadingIndicatorHeightConstraint.constant = 0
            self.view.layoutIfNeeded()
        }) { (_) in
            self.activiyIndicatorWrapper.backgroundColor = .clear
        }
    }
}

extension ViewController {
    
    private func setStatusView(withTrip trip: Trip, andData data: TripData) {        
        self.statusView.setStatus(forTrip: trip, andData: data)
    }
}
