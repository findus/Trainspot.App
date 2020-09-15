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
    @IBOutlet weak var imageView: UIImageView!
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
    private let manager = TrainLocationProxy.shared
    
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
    
    private var tripTimeFrameLocationController = TrainLocationTripByTimeFrameController()
    
    private let tripProvider = MockTrainDataJourneyProvider.init()
    
    private var lastLocation: CLLocation? {
        didSet {
            self.calcBearing()
        }
    }
    
    private var pinnedLocation: CLLocation? {
        didSet {
            self.calcBearing()
            
            if self.pinnedLocation != nil {
                self.imageView.isHidden = false
            } else {
                self.imageView.isHidden = true
            }
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
        self.imageView.transform = CGAffineTransform(rotationAngle: angle)
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
           
            self.tripTimeFrameLocationController.setCurrentLocation(location: location)
        }
      
        UIView.animate(withDuration: 0.5) {
            self.heading = CGFloat(newHeading.trueHeading)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        lastLocation = currentLocation
        self.tripTimeFrameLocationController.setCurrentLocation(location: currentLocation)
        
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
            // Just a fancy curve to slowly slow down animation speed while panning
            self.loadingIndicatorHeightConstraint.constant = transform.y > 0 ? 0: 9*(pow(abs(transform.y), 0.5)) + initialConstraintValue
        }
       
    }
}

// MARK: - Lifecycle

extension ViewController {
      override func viewDidLoad() {
           super.viewDidLoad()
    
           self.manager.delegate?.append(self)
           self.imageView.isHidden = true

           UserLocationController.shared.register(delegate: self)
            
           #if MOCK
           var components = DateComponents()
           components.second = 0
           components.hour = 0
           components.minute = 0
           components.day = 14
           components.month = 9
           components.year = 2020
           let date = Calendar.current.date(from: components)
           let traveler = TimeTraveler()
           Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
               traveler.travel(by: 1)
           }
           traveler.date = date!
           tripTimeFrameLocationController = TrainLocationTripByTimeFrameController(dateGenerator: traveler.generateDate)
           tripTimeFrameLocationController.setDataProvider(withProvider: TripProvider(MockTrainDataTimeFrameProvider(withFile: "bs_delay")))
           #else
           tripTimeFrameLocationController.setDataProvider(withProvider: TripProvider(NetworkTrainDataTimeFrameProvider()))
           #endif
           
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
           
           self.proportionalHeightConstraint.isActive = true
           
           self.statusView.isHidden = true
           self.proportionalHeightConstraint.constant = -200

           self.setupBus()

           self.mapViewController?.delegate = self
           
           if UserPrefs.isManualLocationEnabled() {
               self.tripTimeFrameLocationController.setCurrentLocation(location: UserPrefs.getManualLocation())
               
               guard let selectedTrip = self.selectedTrip else {
                   return
               }
               
               let location = selectedTrip.nearestTrackPosition(forUserLocation: UserPrefs.getManualLocation())
               self.mapViewController?.setLineToNearestTrack(forTrackPosition: location, andUserlocation: UserPrefs.getManualLocation().coordinate)
           }
        
        // Onboarding
        
       // if UserPrefs.getfirstOnboardingTriggered() == false {
            self.displayTutorial()
       // }
    }
    
    override func viewDidAppear(_ animated: Bool) {

        if self.firstLaunch == false {
            self.manager.register(controller: tripTimeFrameLocationController)
            self.tripTimeFrameLocationController.fetchServer()
            self.toggleStatusView()
            self.firstLaunch = true
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
        case .error(let description):
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
        tripTimeFrameLocationController.setCurrentLocation(location: location)
        
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
            if let id = notification?.object as? String {
                self.tripIdToUpdateLocation = id
            }
        }
        
        SwiftEventBus.onMainThread(self, name: "deSelectTripOnMap") { (notification) in
            self.tripIdToUpdateLocation = nil
        }
        
        SwiftEventBus.onMainThread(self, name: "UpdatedSettings") { (notification) in
            self.mapViewController?.removeAllEntries()
            self.tripTimeFrameLocationController.fetchServer()
        }
        
        SwiftEventBus.onMainThread(self, name: "useManualPosition") { (notification) in
            
            guard let enabled = notification?.object as? Bool else {
                return
            }
            
            if enabled == true {
                                
                self.tripTimeFrameLocationController.setCurrentLocation(location: UserPrefs.getManualLocation())
                self.tripTimeFrameLocationController.fetchServer()
                
            } else {
                
                self.tripTimeFrameLocationController.fetchServer()
            }
        }
    }
    
}

//MARK: Onboarding

extension ViewController: AutoCompleteDelegate {
    
    private func displayTutorial() {
        let storyboard = UIStoryboard(name: "Introduction", bundle: nil)
        let vc = (storyboard.instantiateViewController(withIdentifier: "introduction") as! IntroductionBaseViewController)
        vc.onDone = {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.triggerStationSelection()
            }
        }
        self.present(vc, animated: true)
        
        UserPrefs.setfirstOnboardingTriggered(true)
    }
    
    private func triggerStationSelection() {
        let controller = AutoCompleteViewController(nibName: "AutoCompleteViewController", bundle: nil)
        
        let content = CsvReader.shared.getAll()
        controller.delegate = self
        controller.data = content?.map({ (a) -> String in
            a.stationName
        })
        
        self.present(controller, animated: true, completion: nil)
    }
    
    func onValueSelected(_ value: String?) {
        
        guard let newStationName = value  else {
            return
        }
        
        Log.info("User selected \(newStationName) as new station")
        
        guard let data = CsvReader.shared.getStationInfo(withContent: newStationName)?.first?.ibnr else {
            Log.error("Could not find ibnr for station named \(newStationName)")
            return
        }
        
        let stationInfo = StationInfo(newStationName, data)
        
        UserPrefs.setSelectedStation(stationInfo)
        SwiftEventBus.post("UpdatedSettings")
    }
    
}
