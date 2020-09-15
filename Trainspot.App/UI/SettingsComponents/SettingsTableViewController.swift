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
import SwiftEventBus
import CoreLocation
import NotificationBannerSwift

class SettingsTableViewController: UITableViewController  {
    
    @IBOutlet weak var timeOffsetSlider: UISlider!
    @IBOutlet weak var timeOffsetLabel: UILabel!
    @IBOutlet weak var stationLabel: UILabel!
    
    @IBOutlet weak var macDistanceLabel: UILabel!
    @IBOutlet weak var maxDistanceSlider: UISlider!
    
    @IBOutlet weak var useManualPosition: UISwitch!
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        // Show tutorial
        if indexPath.row == 5 {
            self.displayTutorial()
        }
        
    }
    
    private func displayTutorial() {
        let storyboard = UIStoryboard(name: "Introduction", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "introduction")
        self.present(vc, animated: true)
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        
        if sender.accessibilityIdentifier == "offsetSlider" {
            timeOffsetLabel.text = String(Int(sender.value))
        }
        
        if sender.accessibilityIdentifier == "maxDistanceSlider" {
            macDistanceLabel.text = String(Int(sender.value))
        }
        
    }
    
    @IBAction func sliderOnTouchUp(_ sender: UISlider) {
        
        if sender.accessibilityIdentifier == "offsetSlider" {
            UserPrefs.setTimeOffset(Int(self.timeOffsetSlider.value))
            SwiftEventBus.post("UpdatedSettings")
        }
        
        if sender.accessibilityIdentifier == "maxDistanceSlider" {
            UserPrefs.setMaxDistance(Int(self.maxDistanceSlider.value))
            SwiftEventBus.post("UpdatedSettings")
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
    
    @IBAction func onLocationSettingsTapped(_ sender: Any) {
        
        if self.useManualPosition.isOn == false
            && (CLLocationManager.authorizationStatus() == .notDetermined
            || CLLocationManager.authorizationStatus() == .denied) {
            
            let banner = FloatingNotificationBanner(
                title: "Aktiviere Location Dienste für die App",
                subtitle: "Du hast der App nicht erlaubt die Location-Dienste zu verwenden, aktiviere dies in den Einstellungen.", style: .warning)
            
            banner.autoDismiss = true
            banner.haptic = .medium
            banner.show()
            self.useManualPosition.isOn = true
        }
        
        UserPrefs.setManualPositionDetermination(self.useManualPosition.isOn)
        
        if useManualPosition.isOn {
            SwiftEventBus.post("useManualPosition", sender: true)
        } else {
            SwiftEventBus.post("useManualPosition", sender: false)
            UserLocationController.shared.reask()
        }
        
    }
}

// MARK: - Lifecycle

extension SettingsTableViewController {
    override func viewDidLoad() {
        Log.info("Setup setting view...")
        
        //Time offset
        timeOffsetSlider.maximumValue = 100
        timeOffsetSlider.minimumValue = 0
        
        timeOffsetSlider.value = Float(UserPrefs.getTimeOffset())
        timeOffsetLabel.text = String(UserPrefs.getTimeOffset())
        
        // Max distance
        maxDistanceSlider.maximumValue = 9000
        maxDistanceSlider.minimumValue = 100
        
        // StationData
        let stationData = UserPrefs.getSelectedStation()
        self.stationLabel.text = stationData.name
        
        self.dismissKey()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.maxDistanceSlider.value = Float(UserPrefs.getMaxDistance())
        self.macDistanceLabel.text = String(UserPrefs.getMaxDistance())
        self.useManualPosition.isOn = UserPrefs.getManualPositionDetermination()
    }
    
}

// MARK: - Autocomplete Delegate

extension SettingsTableViewController: AutoCompleteDelegate {
    
    func onValueSelected(_ value: String?) {
        guard let newStationName = value  else {
            return
        }
        
        Log.info("User selected \(newStationName) as new station")
        self.stationLabel.text = newStationName
        
        guard let data = CsvReader.shared.getStationInfo(withContent: newStationName)?.first?.ibnr else {
            Log.error("Could not find ibnr for station named \(newStationName)")
            return
        }
        
        let stationInfo = StationInfo(newStationName, data)
        
        UserPrefs.setSelectedStation(stationInfo)
        SwiftEventBus.post("UpdatedSettings")
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
