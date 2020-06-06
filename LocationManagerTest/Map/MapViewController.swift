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
        let pin = MKPointAnnotation()
        pin.coordinate = entry.location.coordinate
        pin.title = entry.name
        markerDict[entry.name] = pin
        self.map.addAnnotation(pin)
        
        let region = MKCoordinateRegion(center: pin.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        map.setRegion(region, animated: true)
    }
    
    
    func drawLine(entries: Array<MapEntity>) {
        let coords = entries.map { $0.location.coordinate }
        let polyline = MKPolyline(coordinates: coords, count: coords.count)
        self.map.addOverlay(polyline)
    }
    
    func deleteEntry(withName: String) {
        
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

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        polylineRenderer.strokeColor = .blue
        polylineRenderer.lineWidth = 2
        return polylineRenderer

    }
    
    func updateTrainLocation(forId id: String, toLocation location: CLLocationCoordinate2D, withDuration duration: Double) {
        guard let entry = self.entryList.filter({ $0.name == id }).first else {
            print("No MapEntry found for \(id), will create entry at location")
            self.addEntry(entry:
                MapEntity(name: id, location: CLLocation(latitude: location.latitude, longitude: location.longitude))
            )
            
            return
        }

        let pin = self.markerDict[entry.name]
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
