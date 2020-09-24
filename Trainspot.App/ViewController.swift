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
import TripVisualizer
import SwiftEventBus
import NotificationBannerSwift
import CSVParser

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var compass: UIImageView!
    @IBOutlet var statusView: StatusView!
    @IBOutlet weak var loadingIndicatorHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomView: UIVisualEffectView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activiyIndicatorWrapper: UIView!
    @IBOutlet weak var statusViewWrapper: UIVisualEffectView!

    @IBOutlet var proportionalHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var statusContainerView: UIView!
    
    @IBOutlet weak var vibrancyView: UIVisualEffectView!
    
    private var initialConstraintValue = CGFloat(0)
    
    private var effectCache: UIVisualEffect?
    
    private var firstLaunch: Bool = false
    
    // Status View Cache values
    private var triggeredUpdate: Bool = false
    private var isStillPulling = false
    
    // Trip Info
    private var selectedTrip: Trip? {
        didSet {
            self.drawHighlightedPolyLineForSelectedTrip()
            if selectedTrip != nil {
                let location = selectedTrip!.nearestTrackPosition(forUserLocation: UserPrefs.getManualLocation())
                self.mapViewController?.setLineToNearestTrack(forTrackPosition: location, andUserlocation: UserPrefs.getManualLocation().coordinate)
            }
            
        }
    }
    
    private let generator = UINotificationFeedbackGenerator()
    
    
    private var mapViewController: MapViewController?
    
    private var tripIdToUpdateLocation: String? {
        didSet {
            if tripIdToUpdateLocation != nil {
                UIView.animate(withDuration: 0.25) {
                    self.statusView.isHidden = false
                    self.proportionalHeightConstraint.constant = 0
                    self.view.layoutIfNeeded()
                }
            } else {
                UIView.animate(withDuration: 0.25) {
                    self.statusView.isHidden = true
                    self.proportionalHeightConstraint.constant = -200
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
    
    private var lastLocation: CLLocation? {
        didSet {
            self.calcBearing()
        }
    }
    
    private var pinnedLocation: CLLocation? {
        didSet {
            self.calcBearing()
            self.setCompasOpacity()
        }
    }
    
    private func setCompasOpacity() {
        
        UIView.animate(withDuration: 0.25) {
            self.compass.alpha = (UserPrefs.isManualLocationEnabled() == false && self.tripIdToUpdateLocation != nil) ? 0.5 : 0
        }
    }
    
    private var heading: CGFloat? {
        didSet {
            self.calcBearing()
        }
    }
    
    private var pinnedLocationBearing: CGFloat {
        return lastLocation?.bearingToLocationRadian(self.pinnedLocation ?? CLLocation()) ?? 0
    }
     
    private func calcBearing() {
        let angle = self.computeNewAngle(with: CGFloat(self.heading ?? 0))
        self.compass.transform = CGAffineTransform(rotationAngle: angle)
    }
    
    func computeNewAngle(with newAngle: CGFloat) -> CGFloat {
        let origHeading = self.pinnedLocationBearing - newAngle.toRadians
        return origHeading
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // TODO: Check vibrancy after light->darkmode change
        if self.traitCollection.userInterfaceStyle == .light {
          
            self.effectCache = self.vibrancyView.effect
            self.vibrancyView.effect = nil
        } else {
            
            guard let effect = self.effectCache else {
                return
            }
            
            self.vibrancyView.effect = effect
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
      
        if let location = manager.location {
            TripHandler.shared.setCurrentLocation(location)
        }
      
        UIView.animate(withDuration: 0.5) {
            self.heading = CGFloat(newHeading.trueHeading)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        lastLocation = currentLocation
        TripHandler.shared.setCurrentLocation(currentLocation)

        // set nearest track polyline
        guard let selectedTrip = self.selectedTrip else {
            return
        }
        
        let location = selectedTrip.nearestTrackPosition(forUserLocation: currentLocation)
        self.mapViewController?.setLineToNearestTrack(forTrackPosition: location, andUserlocation: currentLocation.coordinate)
    }
    
    private func toggleStatusView() {
        UIView.animate(withDuration: 0.25, animations: {
            self.proportionalHeightConstraint.constant = -200
            self.view.layoutIfNeeded()
            
            self.statusView.isHidden = true

        })
    }

}

extension ViewController: UIGestureRecognizerDelegate {
    
    @objc func tapped(gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            if let selectedTrip = TripHandler.shared.getSelectedTripID() {
                self.mapViewController?.centerCamera(atTripWithId:selectedTrip)
            }
        }
    }
    
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
                TripHandler.shared.triggerUpdate()
            }
            // Just a fancy curve to slowly slow down animation speed while panning
            self.loadingIndicatorHeightConstraint.constant = transform.y > 0 ? 0: 9*(pow(abs(transform.y), 0.5)) + initialConstraintValue
        }
       
    }
}

// MARK: - Lifecycle

extension ViewController {
      override func viewDidLoad() {
        super.viewDidLoad()
        
        TrainLocationProxy.shared.addListener(listener: self)
        
        //self.compass.isHidden = true

           UserLocationController.shared.register(delegate: self)
           
           self.statusView.startTimer()
           self.bottomView.layer.shadowOpacity = 0.7
           self.bottomView.layer.shadowOffset = CGSize(width: 3, height: 3)
           self.bottomView.layer.shadowRadius = 15.0
           self.bottomView.layer.shadowColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
           
           // Pan reload gesture
           
           let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.dragged(gesture:)))
        
        let touchGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapped(gesture:)))
           
           self.bottomView.addGestureRecognizer(gesture)
           gesture.delegate = self
       
           self.bottomView.addGestureRecognizer(touchGesture)
           touchGesture.delegate = self
        
           self.loadingIndicator.isHidden = true
           self.loadingIndicatorHeightConstraint.constant = 0
           
           self.proportionalHeightConstraint.isActive = true
           
           self.statusView.isHidden = true
           self.proportionalHeightConstraint.constant = -200

           self.setupBus()

           self.mapViewController?.delegate = self
           
           if UserPrefs.isManualLocationEnabled() {
          
            TripHandler.shared.setCurrentLocation(UserPrefs.getManualLocation())
               
               guard let selectedTrip = self.selectedTrip else {
                   return
               }
               
               let location = selectedTrip.nearestTrackPosition(forUserLocation: UserPrefs.getManualLocation())
               self.mapViewController?.setLineToNearestTrack(forTrackPosition: location, andUserlocation: UserPrefs.getManualLocation().coordinate)
           }
        
        //TODO only for reloading lines, write additional logic that refreshes new registered vcs accordingly
        TripHandler.shared.triggerUpdate()
                
    }
    
    override func viewDidAppear(_ animated: Bool) {

        if self.firstLaunch == false {
            self.toggleStatusView()
            self.firstLaunch = true
        }
        
        if UserPrefs.infoDialogShownFor(String(describing: self.classForCoder)) == false {
            self.displayTutorial()
            UserPrefs.setInfoDialogShownFor(String(describing: self.classForCoder))
        }
        
        self.setCompasOpacity()

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Aligns the Mapviews' content view to the status view
        let tabbarHeight = self.tabBarController!.tabBar.frame.height
        let statusView = self.bottomView.frame.height
        let offset = 4
        mapViewController?.setBottomContentAnchor((tabbarHeight + statusView) - CGFloat(offset))
    }
       
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc1 as MapViewController:
            self.mapViewController = vc1
        default:
            break
        }
    }
}

extension ViewController: TrainLocationDelegate {
    var id: String {
        return "viewcontroller"
    }
    
    func removeTripFromMap(forTrip trip: Trip) {
        self.mapViewController?.deleteEntry(withName: trip.tripId, andLabel: trip.name)
        if trip.tripId == self.tripIdToUpdateLocation {
            self.tripIdToUpdateLocation = nil
        }
    }
    
    func drawPolyLine(forTrip: Trip) {
        self.mapViewController?.drawLine(forTrip: forTrip, withLineType: .normal)
    }
    
    private func drawHighlightedPolyLineForSelectedTrip() {
        
        guard let selectedTrip = self.selectedTrip else {
            return
        }
        
        self.mapViewController?.drawLine(forTrip: selectedTrip, withLineType: .selected)
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
            if self.loadingIndicatorHeightConstraint.constant == 0 {
                self.loadingIndicatorHeightConstraint.constant = 40
            }
            self.view.layoutIfNeeded()
            self.generator.notificationOccurred(.success)
        }
    }
    
    public func onUpdateEnded(withResult result: Result) {
        self.triggeredUpdate = false
        self.loadingIndicator.isHidden = true
        generator.notificationOccurred(.success)
        self.activiyIndicatorWrapper.backgroundColor = #colorLiteral(red: 0.1996439938, green: 0.690910533, blue: 0.4016630921, alpha: 0.759765625)
        
        switch result {
        case .success:
            Log.trace("Update of train data successful")
        case .error( _):
            printErrorNotification()
        case .noTripsFound:
            printNoTripsFoundNotication()
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            self.loadingIndicatorHeightConstraint.constant = 0
            self.view.layoutIfNeeded()
        }) { (_) in
            self.activiyIndicatorWrapper.backgroundColor = .clear
        }
    }
    
    private func printErrorNotification() {
        printNotification(
            withTitle: "Fehler beim Abfragen der Fahrplandaten",
            andBody: "Prüfe deine Internetverbidnung oder versuche es später noch einmal."
            , andStyle: .danger)
    }
    
    private func printNoTripsFoundNotication() {
        printNotification(
            withTitle: "Keine Fahrten in deiner Nähe gefunden",
            andBody: "Erhöhe die Reichweite in den Einstellungen, wähle einen anderen Bahnhof aus oder setze eine manuelle Wegmarke"
            , andStyle: .warning)
    }
    
    private func printNotification(withTitle title:String, andBody body: String, andStyle style: BannerStyle) {
        DispatchQueue.main.async {
            let banner = FloatingNotificationBanner(
                title: title,
                subtitle: body, style: style)
            
            banner.autoDismiss = true
            banner.haptic = .heavy
            banner.show()
        }
    }
}

extension ViewController {
    
    private func setStatusView(withTrip trip: Trip, andData data: TripData) {
        if self.selectedTrip?.tripId != trip.tripId {
            self.selectedTrip = trip
        }
        self.statusView.setStatus(forTrip: trip, andData: data)
    }
}

// MARK: - Mapview Controller

extension ViewController: MapViewControllerDelegate {
    func userPressedAt(location: CLLocation) {
        self.generator.notificationOccurred(.success)
        
        UserPrefs.setManualLocation(location)
        TripHandler.shared.setCurrentLocation(location)

        guard let selectedTrip = self.selectedTrip else {
            return
        }
        
        let location = selectedTrip.nearestTrackPosition(forUserLocation: UserPrefs.getManualLocation())
        self.mapViewController?.setLineToNearestTrack(forTrackPosition: location, andUserlocation: UserPrefs.getManualLocation().coordinate)
    }
}

// MARK: - Eventbus logic

extension ViewController {
    
    private func setupBus() {
        SwiftEventBus.onMainThread(self, name: "selectTripOnMap") { (notification) in
            if let trip = notification?.object as? Trip {
                self.tripIdToUpdateLocation = trip.tripId
            } else if let tripID = notification?.object as? String {
                self.tripIdToUpdateLocation = tripID
            }
        }
        
        SwiftEventBus.onMainThread(self, name: "deSelectTripOnMap") { (notification) in
            self.tripIdToUpdateLocation = nil
            self.setCompasOpacity()
        }
        
        SwiftEventBus.onMainThread(self, name: "UpdatedSettings") { (notification) in
            self.mapViewController?.removeAllEntries()
            TripHandler.shared.triggerUpdate()
        }
        
        SwiftEventBus.onMainThread(self, name: "useManualPosition") { (notification) in
            
            guard let enabled = notification?.object as? Bool else {
                return
            }
            
            if enabled == true {
                                
                TripHandler.shared.setCurrentLocation(UserPrefs.getManualLocation())
                TripHandler.shared.triggerUpdate()
                
            } else {
                
                TripHandler.shared.triggerUpdate()
            }
        }
    }
    
}

extension ViewController {
    
    private func displayTutorial() {
        let storyboard = UIStoryboard(name: "Introduction", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "Page 2")
        self.present(vc, animated: true)
    }
}
