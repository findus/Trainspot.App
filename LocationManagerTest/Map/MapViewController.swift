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

    let entryList: Array<MapEntity> = Array()
    weak var delegate: MapViewControllerDelegate?
    
    override func viewDidLoad() {
        
        self.map.showsUserLocation = true
        
        let lpgr = UILongPressGestureRecognizer(target: self, action:  #selector(longpress(sender:)))
        lpgr.minimumPressDuration = 0.5
        map.addGestureRecognizer(lpgr)
        
    }
    
    func addEntry(entry: MapEntity) {
        self.setPinOnMap(location: entry.location.coordinate)
    }
    
    func updateEntry(entry: MapEntity) {
        
    }
    
    func deleteEntry(entry: MapEntity) {
        
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
    
    private func setPinOnMap(location: CLLocationCoordinate2D) {
         let pin = MKPlacemark(coordinate: location)
         self.map.addAnnotation(pin)
     }
    
}
