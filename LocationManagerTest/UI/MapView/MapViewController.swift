//
//  MapViewController.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MapViewControllerProtocol {

    
    @IBOutlet weak var map: MKMapView!

    var entryList: Array<MapEntity> = Array()
    var markerDict: Dictionary<String, MKPointAnnotation> = Dictionary.init()
    weak var delegate: MapViewControllerDelegate?
    
    override func viewDidLoad() {
        
        self.map.showsUserLocation = true
        
        let lpgr = UILongPressGestureRecognizer(target: self, action:  #selector(longpress(sender:)))
        lpgr.minimumPressDuration = 0.5
        map.addGestureRecognizer(lpgr)
        
        map.delegate = self;
        
    }
            
    func addEntry(entry: MapEntity) {
        entryList.append(entry)
        let pin = TrainAnnotation()
        pin.coordinate = entry.location.coordinate
        pin.title = entry.name
        pin.tripId = entry.tripId
        markerDict[entry.tripId] = pin
        self.map.addAnnotation(pin)
        
        let region = MKCoordinateRegion(center: self.map.userLocation.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        map.setRegion(region, animated: true)
    }
    
    
    func drawLine(entries: Array<MapEntity>) {
        let coords = entries.map { $0.location.coordinate }
        let polyline = MKPolyline(coordinates: coords, count: coords.count)
        self.map.addOverlay(polyline)
    }
    
    func deleteEntry(withName: String, andLabel: String) {
        guard let annotation = self.markerDict[withName] else {
            Log.warning(" \(andLabel) Could not remove Annottation")
            return
        }
        self.map.removeAnnotation(annotation)
    }
    
    func removeAllEntries() {
        self.map.removeAnnotations(self.map.annotations)
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
        
        let startLoc = CLLocation(latitude: startPoint!.latitude, longitude: startPoint!.longitude)
        let endLoc = CLLocation(latitude: endPoint.latitude, longitude: endPoint.longitude)
        
        let x = startLoc.distance(from: endLoc)

        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: {
           // Update annotation coordinate to be the destination coordinate
            pin!.coordinate = endPoint
        }, completion: nil)
        
    }
    
}

extension MapViewController: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        polylineRenderer.strokeColor = .blue
        polylineRenderer.lineWidth = 2
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
        
        annotationView?.centerOffset = CGPoint(x: 25, y: -20)
        annotationView?.canShowCallout = true
        annotationView?.rightCalloutAccessoryView = UIButton.init(type: .detailDisclosure)
        (annotationView as! MKTrainAnnotationView).label.text = an.title
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
            (annotationView as! MKTrainAnnotationView).icon.image = UIImage(named: "westfalenbahn")
        default:
            (annotationView as! MKTrainAnnotationView).icon.image = UIImage(named: "westfalenbahn")

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
        
        (self.parent as! ViewController).tripIdToUpdateLocation = entry.tripId
    }

}
