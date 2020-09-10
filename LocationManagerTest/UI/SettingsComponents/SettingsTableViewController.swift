//
//  SettingsTableViewController.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 10.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import UIKit
import Log
import CSVParser
import TripVisualizer

class SettingsTableViewController: UITableViewController  {
    
    @IBOutlet weak var timeOffsetSlider: UISlider!
    @IBOutlet weak var timeOffsetLabel: UILabel!
    @IBOutlet weak var stationLabel: UILabel!
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        
        if sender.accessibilityIdentifier == "offsetSlider" {
            timeOffsetLabel.text = String(Int(sender.value))
        }
    }
    
    @IBAction func sliderOnTouchUp(_ sender: UISlider) {
        
        if sender.accessibilityIdentifier == "offsetSlider" {
            UserPrefs.setTimeOffset(Int(self.timeOffsetSlider.value))
        }
    }
    
    @IBAction func stationLabelTapped(_ sender: Any) {
        let controller = AutoCompleteViewController(nibName: "AutoCompleteViewController", bundle: nil)
        
        let content = CsvReader.shared.getAll()
        controller.delegate = self
        controller.data = content?.map({ (a) -> String in
            a.stationName
        })
        
        self.present(controller, animated: true, completion: nil)
    }
    
}

// MARK: - Lifecycle

extension SettingsTableViewController {
    override func viewDidLoad() {
        Log.info("Setup setting view...")
        timeOffsetSlider.maximumValue = 100
        timeOffsetSlider.minimumValue = 0
        
        timeOffsetSlider.value = Float(UserPrefs.getTimeOffset())
        timeOffsetLabel.text = String(UserPrefs.getTimeOffset())
        
        let stationData = UserPrefs.getSelectedStation()
        self.stationLabel.text = stationData.name
        
        self.dismissKey()
            
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        // Tabbed at Station Selection
        if indexPath.row == 0 {
            
        }
        
    }
}

extension SettingsTableViewController: AutoCompleteDelegate {
    func onValueSelected(_ value: String?) {
        guard let newStationName = value  else {
            return
        }
        
        Log.info("User selected \(newStationName) as new station")
        self.stationLabel.text = newStationName
        
        guard let data = CsvReader.shared.getStationInfo(withContent: newStationName)?.first?.ibnr else {
            return
        }
        
        let stationInfo = StationInfo(newStationName, data)
        
        UserPrefs.setSelectedStation(stationInfo)
    }
}

extension UIViewController {
    
    func dismissKey()
        
    {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer( target: self, action: #selector(UIViewController.dismissKeyboard))
        
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
    }
    
    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }
    
}
