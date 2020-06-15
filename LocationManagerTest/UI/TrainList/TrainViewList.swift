//
//  TrainViewList.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 09.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import UIKit
import CoreLocation
import TripVisualizer

public class TrainViewList: UITableViewController {
    
    private let trainLocationProxy = TrainLocationProxy.shared
    private var trips : Array<Trip> = Array.init()
    private var tripData: Dictionary<String, TripData> = Dictionary.init()
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        trainLocationProxy.addListener(listener: self)
        tableView.register(UINib(nibName: "TrainOverViewCell", bundle: nil), forCellReuseIdentifier: "trainOverviewCell2")
    
    }

    // MARK: - Table view data source

    public override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.trips.count
    }


    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "trainOverviewCell2", for: indexPath) as! TrainOverviewCell

        guard let currentTripData = self.tripData[self.trips[indexPath.row].tripId] else {
            return cell
        }
        // Configure the cell...
        cell.name.text = self.trips[indexPath.row].name
        //cell.arrival.text = self.trips[indexPath.row].ar
        //cell.distance.text = self.trips[indexPath.row].shorttestDistanceToTrack(forUserLocation: <#T##CLLocation#>)
        cell.status.text = currentTripData.state.get()
        
        cell.name.layer.cornerRadius = 10
        
        let timeFractions = secondsToHoursMinutesSeconds(seconds: Int(currentTripData.arrival))
        cell.arrival.text = String(format: "%@%02d:%02d:%02d",timeFractions.3 ? "- " : "", timeFractions.0, timeFractions.1,timeFractions.2)
        
        switch currentTripData.state {
        case .Ended:
            cell.status.text = "💤"
        case .Driving(_):
            cell.status.text = "🛤"
        case .Stopped(_):
            cell.status.text = "⏸"
        case .WaitForStart(_):
            cell.status.text = "⏰"
        default:
            cell.status.text = "❓"
        }
        
        return cell
    }

}

extension TrainViewList: TrainLocationDelegate {
    
    public var id: String {
        "StatusOverViewTableView"
    }
    
    public func trainPositionUpdated(forTrip trip: Trip, withData data: TripData, withDuration duration: Double) {
        if !self.trips.contains(where: { $0.tripId == trip.tripId }) {
            self.trips.append(trip)
        }
        self.tripData[trip.tripId] = data
        self.tableView.reloadData()
        
        self.trips = self.trips.sorted { (t1, t2) -> Bool in
            self.tripData[t1.tripId]?.arrival ?? 0.0 <  self.tripData[t2.tripId]?.arrival ?? 0.0
        }
    }
    
    public func removeTripFromMap(forTrip trip: Trip) {
        self.trips.removeAll(where: { $0.tripId == trip.tripId })
        self.tableView.reloadData()
    }
    
    public func drawPolyLine(forTrip: Trip) {
        
    }
    
    public func onUpdateStarted() {
        
    }
    
    public func onUpdateEnded() {
        
    }

}
