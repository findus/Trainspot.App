//
//  MapViewController.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import UIKit
import MapKit
import TripVisualizer
import SwiftEventBus

enum LineType {
    case normal
    case selected
}

class MapViewController: UIViewController {

    
    @IBOutlet weak var map: MKMapView!

    var entryList: Array<MapEntity> = Array()
    var markerDict: Dictionary<String, MKPointAnnotation> = Dictionary.init()
    var lineDict: Dictionary<String, TrainTrackPolyLine> = Dictionary.init()
    
    var fakedUserPosition: MKPointAnnotation?
    
    private var selectedPolyLineTripId: String? {
        didSet {
            if selectedPolyLineTripId == nil && oldValue != nil {
                guard let overlay = self.lineDict[oldValue!] else {
                    return
                }
                
                if let renderer = self.map.renderer(for: overlay) as? MKPolylineRenderer {
                    renderer.strokeColor = .white
                    renderer.lineWidth = 1
                    renderer.invalidatePath()
                }
            }
        }
    }
    
    weak var delegate: MapViewControllerDelegate?
    
    override func viewDidLoad() {
        
        self.map.showsUserLocation = true
        
        let lpgr = UILongPressGestureRecognizer(target: self, action:  #selector(longpress(sender:)))
        lpgr.minimumPressDuration = 0.5
        map.addGestureRecognizer(lpgr)
        
        map.delegate = self;
        
        self.setupEventBusListener()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Check if locationmanager is still active
        self.map.showsUserLocation = !UserPrefs.getManualPositionDetermination()
       
        if UserPrefs.getManualPositionDetermination() {
            self.addFakedUserPosition(onLocation: UserPrefs.getManualLocation().coordinate)
        }
    }
    
    private func centerCamera(atTripWithId id: String) {
        let coords = self.markerDict[id]!.coordinate
        let region = MKCoordinateRegion(center: coords, latitudinalMeters: 10000, longitudinalMeters: 10000)
        map.setRegion(region, animated: true)
    }
    
    private func addFakedUserPosition(onLocation location: CLLocationCoordinate2D) {
        
        if let annotation = self.fakedUserPosition {
            self.map.removeAnnotation(annotation)
        }
        
        let pin = MKPointAnnotation()
        pin.coordinate = location
        self.map.addAnnotation(pin)
        self.fakedUserPosition = pin
    }
    
    private func selectTrip(withId id: String) {
        let annotation = self.markerDict[id]
        self.map.selectAnnotation(annotation!, animated: true)
        
        //Reduces opacity of any other visible, non selected map annotation
        for annotation in self.map.annotations {
            let anView = self.map.view(for: annotation) as? MKTrainAnnotationView
            if let view = anView {
                if (annotation as? TrainAnnotation)?.tripId != id {
                    view.animatedAlpha(toValue: 0.2)
                } else {
                    view.animatedAlpha(toValue: 1.0)
                }
            }
        }
        
    }
    
    /**
     Draws a polyline of the passed trip. Based on the type the line will be rendered differently
     Only one selected line can exists, if another one gets passed to the controller the old one gets redrawn with a normal style
     */
    func drawLine(entries: Array<MapEntity>, withLineType type: LineType) {
        let coords = entries.map { $0.location.coordinate }
        let polyline = TrainTrackPolyLine(coordinates: coords, count: coords.count)
        let tripID = entries.first!.tripId
        
        polyline.type = type
             
        // Checks if another trip is already hightlighted, if true it redraws the trip with the base color
        if type == .selected {
            guard
                let oldSelectedPolyLineTripId = self.selectedPolyLineTripId,
                let oldSelectedTripLine = self.lineDict[oldSelectedPolyLineTripId] else {
                    
                    self.map.addOverlay(polyline)
                    selectedPolyLineTripId = tripID
                    self.lineDict[tripID] = polyline

                    return
            }
            
            oldSelectedTripLine.type = .normal
           
            if let renderer = self.map.renderer(for: oldSelectedTripLine) as? MKPolylineRenderer {
                renderer.strokeColor = .white
                renderer.lineWidth = 1
                renderer.invalidatePath()
            }
            
            self.map.addOverlay(polyline)
            selectedPolyLineTripId = tripID

        } else {
            self.map.insertOverlay(polyline, at: 0)
        }
        
        self.lineDict[tripID] = polyline
        
    }
    
    func removeAllEntries() {
        self.map.removeAnnotations(self.map.annotations)
        self.map.removeOverlays(self.map.overlays)
        self.selectedPolyLineTripId = nil
        self.markerDict = Dictionary.init()
        self.lineDict = Dictionary.init()
        self.entryList = Array.init()
    }
    
    @objc func longpress(sender: UIGestureRecognizer) {
        guard sender.state == .began else { return }
        let location = sender.location(in: self.map)
        let coord = self.map.convert(location, toCoordinateFrom: self.map)
        self.addFakedUserPosition(onLocation: coord)
        self.delegate?.userPressedAt(location: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
    }
    
}

// MARK: - MapViewControllerProtocol

extension MapViewController: MapViewControllerProtocol {
    
    func deleteEntry(withName: String, andLabel: String) {
        guard let annotation = self.markerDict[withName] else {
            Log.warning(" \(andLabel) Could not remove Annottation")
            return
        }
        self.map.removeAnnotation(annotation)
        
        guard let line = self.lineDict[withName] else {
            Log.warning(" \(andLabel) Could not remove Line")
            return
        }
        self.map.removeOverlay(line)
    }
    
    func addEntry(entry: MapEntity) {
        entryList.append(entry)
        let pin = TrainAnnotation()
        pin.coordinate = entry.location.coordinate
        pin.title = entry.name
        pin.tripId = entry.tripId
        markerDict[entry.tripId] = pin
        self.map.addAnnotation(pin)
    }
    
    func updateTrainLocation(forId id: String, withLabel label: String, toLocation location: CLLocationCoordinate2D, withDuration duration: Double) {
        guard let entry = self.entryList.filter({ $0.tripId == id }).first else {
            print("No MapEntry found for \(id), will create entry at location")
            self.addEntry(entry:
                MapEntity(name: label, tripId: id, location: CLLocation(latitude: location.latitude, longitude: location.longitude))
            )
            
            return
        }
        
        let pin = self.markerDict[entry.tripId]
        let endPoint = location
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: {
            // Update annotation coordinate to be the destination coordinate
            pin!.coordinate = endPoint
        }, completion: nil)
        
    }
    
}

//MARK: - MKMapviewDelegate

extension MapViewController: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        let line = overlay as! TrainTrackPolyLine
        let polylineRenderer = MKPolylineRenderer(overlay: line)
        if line.type == .some(.selected) {
            polylineRenderer.strokeColor = #colorLiteral(red: 0.9215893149, green: 0.2225639522, blue: 0.2431446314, alpha: 0.8295162671)
            polylineRenderer.lineWidth = 2
        } else {
            polylineRenderer.strokeColor = #colorLiteral(red: 0.7667021683, green: 0.7898159898, blue: 0.7819377446, alpha: 1)
            polylineRenderer.lineWidth = 1
        }
        return polylineRenderer

    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        
        var annotationView: MKTrainAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: "annotationView") as? MKTrainAnnotationView
        
        if annotationView == nil {
            annotationView = MKTrainAnnotationView.loadViewFromNib()
        }
        
        guard let an = (annotation as? TrainAnnotation) else {
            return  nil
        }
        
        guard let view = annotationView else {
            return nil
        }
        
        if self.selectedPolyLineTripId != nil && an.tripId != self.selectedPolyLineTripId! {
            view.alpha = 0.2
        }
        
        view.positionDot.layer.cornerRadius = 2
        view.centerOffset = CGPoint(x: 0, y: (-(view.frame.height) / 2) + 2)
        view.canShowCallout = true
        view.rightCalloutAccessoryView = UIButton.init(type: .detailDisclosure)
        
        view.icon.isHidden = false
        view.label.isHidden = true
        view.label.layer.masksToBounds = true

        switch an.title! {
        case let str where str.lowercased().contains("eno"):
            view.icon.image = #imageLiteral(resourceName: "enno")
        case let str where str.lowercased().contains("erx"):
            view.icon.image = #imageLiteral(resourceName: "erixx")
        case let str where str.lowercased().contains("wfb"):
            view.icon.image = #imageLiteral(resourceName: "westalenbahn")
        case let str where str.lowercased().contains("ice"):
            view.icon.image = #imageLiteral(resourceName: "ice")
        case let str where str.lowercased().contains("ic "):
            view.icon.image = #imageLiteral(resourceName: "ic")
        case let str where str.lowercased().contains("rb") || str.lowercased().contains("re"):
            view.icon.isHidden = true
            view.label.isHidden = false
            view.label.text = an.title
        default:
            view.icon.isHidden = true
            view.label.isHidden = false
            view.label.text = an.title
        }

        return view
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else
        {
            return
        }
        
        guard let tripId = (annotation as? TrainAnnotation)?.tripId else {
            return
        }
        
        // TODO pass tripId to Annotation
        guard let entry = self.entryList.filter({ $0.tripId == tripId }).first else {
            return
        }
        
        SwiftEventBus.post("selectTripOnMap",sender: entry.tripId)
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
       
        SwiftEventBus.post("deSelectTripOnMap")
        
        self.selectedPolyLineTripId = nil
        self.resetOpacity()
    }

}

//MARK: -- Event Bus Handling

extension MapViewController {
    private func setupEventBusListener() {
        SwiftEventBus.onMainThread(self, name: "selectTripOnMap") { notification in
            if let tripId = notification?.object as? String {
                self.centerCamera(atTripWithId: tripId)
                self.selectTrip(withId: tripId)
            }
        }
    }
    
    private func resetOpacity() {
        for annotation in self.map.annotations {
            let anView = self.map.view(for: annotation) as? MKTrainAnnotationView
            if let view = anView {
                view.animatedAlpha(toValue: 1.0)
            }
        }
    }
}
