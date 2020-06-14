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
        let cell = tableView.dequeueReusableCell(withIdentifier: "trainOverviewCell", for: indexPath) as! TrainOverviewCell

        // Configure the cell...
        cell.name.text = self.trips[indexPath.row].name
        //cell.arrival.text = self.trips[indexPath.row].ar
        //cell.distance.text = self.trips[indexPath.row].shorttestDistanceToTrack(forUserLocation: <#T##CLLocation#>)
        cell.status.text = self.tripData[self.trips[indexPath.row].tripId]?.state.get()
        
        return cell
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

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
    }
    
    public func removeTripFromMap(forTrip trip: Trip) {
        self.trips.removeAll(where: { $0.tripId == trip.tripId })
        self.tableView.reloadData()
    }
    
    public func drawPolyLine(forTrip: Trip) {
        
    }

}
