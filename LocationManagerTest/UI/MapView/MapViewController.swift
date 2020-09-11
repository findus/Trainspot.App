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

class MapViewController: UIViewController, MapViewControllerProtocol {

    
    @IBOutlet weak var map: MKMapView!

    var entryList: Array<MapEntity> = Array()
    var markerDict: Dictionary<String, MKPointAnnotation> = Dictionary.init()
    var lineDict: Dictionary<String, TrainTrackPolyLine> = Dictionary.init()
    private var selectedPolyLineTripId: String?
    
    weak var delegate: MapViewControllerDelegate?
    
    override func viewDidLoad() {
        
        self.map.showsUserLocation = true
        
        let lpgr = UILongPressGestureRecognizer(target: self, action:  #selector(longpress(sender:)))
        lpgr.minimumPressDuration = 0.5
        map.addGestureRecognizer(lpgr)
        
        map.delegate = self;
        
        self.setupEventBusListener()
        
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
    
    private func centerCamera(atTripWithId id: String) {
        let coords = self.markerDict[id]!.coordinate
        let region = MKCoordinateRegion(center: coords, latitudinalMeters: 10000, longitudinalMeters: 10000)
        map.setRegion(region, animated: true)
    }
    
    private func selectTrip(withId id: String) {
        let annotation = self.markerDict[id]
        self.map.selectAnnotation(annotation!, animated: true)
    }
    
    func drawLine(entries: Array<MapEntity>, withLineType type: LineType) {
        let coords = entries.map { $0.location.coordinate }
        let polyline = TrainTrackPolyLine(coordinates: coords, count: coords.count)
        let tripID = entries.first!.tripId
        
        polyline.type = type
                        
        if type == .selected {
            guard
                let oldSelectedPolyLineTripId = self.selectedPolyLineTripId,
                let oldSelectedTripLine = self.lineDict[oldSelectedPolyLineTripId] else {
                    
                return
            }
            
            self.map.removeOverlay(oldSelectedTripLine)
            oldSelectedTripLine.type = .normal
            self.map.addOverlay(oldSelectedTripLine)
            self.map.addOverlay(polyline)
        } else {
            self.map.insertOverlay(polyline, at: 0)
        }
        
        selectedPolyLineTripId = tripID
        self.lineDict[tripID] = polyline
        
    }
    
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
    
    func removeAllEntries() {
        self.map.removeAnnotations(self.map.annotations)
        self.map.removeOverlays(self.map.overlays)
    }
    
    @objc func longpress(sender: UIGestureRecognizer) {
        guard sender.state == .began else { return }
        let location = sender.location(in: self.map)
        let coord = self.map.convert(location, toCoordinateFrom: self.map)
        self.delegate?.userPressedAt(location: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
    }
    
}

extension MapViewController {
   
    func updateTrainLocation(forId id: String, withLabel label: String, toLocation location: CLLocationCoordinate2D, withDuration duration: Double) {
        guard let entry = self.entryList.filter({ $0.tripId == id }).first else {
            print("No MapEntry found for \(id), will create entry at location")
            self.addEntry(entry:
                MapEntity(name: label, tripId: id, location: CLLocation(latitude: location.latitude, longitude: location.longitude))
            )
            
            return
        }

        let pin = self.markerDict[entry.tripId]
        let startPoint = pin?.coordinate
        let endPoint = location
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: {
           // Update annotation coordinate to be the destination coordinate
            pin!.coordinate = endPoint
        }, completion: nil)
        
    }
    
}

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
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "annotationView")
        
        if annotationView == nil {
            annotationView = MKTrainAnnotationView.loadViewFromNib()
        }
        
        guard let an = (annotation as? TrainAnnotation) else {
            return  nil
        }
        
        (annotationView as! MKTrainAnnotationView).positionDot.layer.cornerRadius = 2
        annotationView?.centerOffset = CGPoint(x: 0, y: (-(annotationView?.frame.height)! / 2) + 2)
        annotationView?.canShowCallout = true
        annotationView?.rightCalloutAccessoryView = UIButton.init(type: .detailDisclosure)
        
        (annotationView as! MKTrainAnnotationView).icon.isHidden = false
        (annotationView as! MKTrainAnnotationView).label.isHidden = true
        (annotationView as! MKTrainAnnotationView).label.layer.masksToBounds = true

        switch an.title! {
        case let str where str.lowercased().contains("eno"):
            (annotationView as! MKTrainAnnotationView).icon.image = #imageLiteral(resourceName: "enno")
        case let str where str.lowercased().contains("erx"):
            (annotationView as! MKTrainAnnotationView).icon.image = #imageLiteral(resourceName: "erixx")
        case let str where str.lowercased().contains("wfb"):
            (annotationView as! MKTrainAnnotationView).icon.image = #imageLiteral(resourceName: "westalenbahn")
        case let str where str.lowercased().contains("ice"):
            (annotationView as! MKTrainAnnotationView).icon.image = #imageLiteral(resourceName: "ice")
        case let str where str.lowercased().contains("ic "):
            (annotationView as! MKTrainAnnotationView).icon.image = #imageLiteral(resourceName: "ic")
        case let str where str.lowercased().contains("rb") || str.lowercased().contains("re"):
            (annotationView as! MKTrainAnnotationView).icon.isHidden = true
            (annotationView as! MKTrainAnnotationView).label.isHidden = false
            (annotationView as! MKTrainAnnotationView).label.text = an.title
        default:
            (annotationView as! MKTrainAnnotationView).icon.isHidden = true
            (annotationView as! MKTrainAnnotationView).label.isHidden = false
            (annotationView as! MKTrainAnnotationView).label.text = an.title
        }

        return annotationView
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
}
