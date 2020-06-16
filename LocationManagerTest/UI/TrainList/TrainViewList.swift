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
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
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
        
        let trip = self.trips[indexPath.row]
        let data = self.tripData[trip.tripId]!
        
        return self.updateCell(withTrip: trip, andTripData: data, atCell: cell)
    }

}

extension TrainViewList: TrainLocationDelegate {
    
    public var id: String {
        "StatusOverViewTableView"
    }
    
    public func trainPositionUpdated(forTrip trip: Trip, withData data: TripData, withDuration duration: Double) {
        if !self.trips.contains(where: { $0.tripId == trip.tripId }) {
            self.trips.append(trip)
            self.tableView.reloadData()
        }
        self.tripData[trip.tripId] = data
        
        self.trips = self.trips.sorted { (t1, t2) -> Bool in
            self.tripData[t1.tripId]?.arrival ?? 0.0 <  self.tripData[t2.tripId]?.arrival ?? 0.0
        }
        
        if let cell = self.tableView.visibleCells.filter({ ($0 as! TrainOverviewCell).tripId == trip.tripId }).first {
            self.updateCell(withTrip: trip, andTripData: self.tripData[trip.tripId]!, atCell: cell as! TrainOverviewCell)
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
        
    private func updateCell(withTrip trip: Trip, andTripData tripData: TripData, atCell cell: TrainOverviewCell) -> TrainOverviewCell {
        
        cell.tripId = trip.tripId
        
        // Configure the cell...
        cell.name.text = trip.name
        
        cell.status.text = tripData.state.get()
        
        cell.name.layer.cornerRadius = 10
        
        let timeFractions = secondsToHoursMinutesSeconds(seconds: Int(tripData.arrival))
        cell.arrival.text = String(format: "%@%02d:%02d",timeFractions.3 ? "- " : "", timeFractions.1,timeFractions.2)
        
        switch tripData.state {
        case .Ended:
            cell.status.text = "💤"
        case .Driving(_):
            cell.status.text = "🛤"
        case .Stopped(_,_):
            cell.status.text = "⏸"
        case .WaitForStart(_):
            cell.status.text = "⏰"
        default:
            cell.status.text = "❓"
        }
        
        switch cell.name.text! {
        case let str where str.lowercased().contains("eno"):
            cell.name.backgroundColor = #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)
        case let str where str.lowercased().contains("erx"):
            cell.name.backgroundColor = #colorLiteral(red: 0.4392156899, green: 0.01176470611, blue: 0.1921568662, alpha: 1)
        case let str where str.lowercased().contains("wfb"):
            cell.name.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        case let str where str.lowercased().contains("ice"):
            cell.name.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.3318062339, blue: 0.2944166345, alpha: 1)
        case let str where str.lowercased().contains("ic "):
            cell.name.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        case let str where str.lowercased().contains("rb") || str.lowercased().contains("re"):
            cell.name.backgroundColor = #colorLiteral(red: 0.7185120558, green: 0.1144746656, blue: 0.1193621281, alpha: 0.8186001712)
        default:
            cell.name.backgroundColor = .clear
        }
        
        let info: String = {
            switch tripData.state {
            case .Driving(let nextStop):
                return "\(nextStop ?? "Hell")"
            case .WaitForStart(let start):
                let formatted = secondsToHoursMinutesSeconds(seconds: Int(start))
                return "\(String(format: "%02d:%02d", formatted.1, formatted.2))"
            case .Stopped(let date, let stop):
                return "\(Int(date.timeIntervalSince(Date())))s \(stop)"
            case .Ended:
                return "Ended"
            default:
                return ""
            }
        }()
        cell.info.text = info
        
        return cell
    }

}
