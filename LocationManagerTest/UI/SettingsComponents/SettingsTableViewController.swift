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

class SettingsTableViewController: UITableViewController  {
    
    @IBOutlet weak var distanceSlider: UISlider!
    @IBOutlet weak var distanceLabel: UILabel!
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        distanceLabel.text = String(Int(sender.value))

    }
    
}

// MARK: - Lifecycle

extension SettingsTableViewController {
    override func viewDidLoad() {
        Log.info("Setup setting view...")
        distanceSlider.maximumValue = 100
        distanceSlider.minimumValue = 0
        
        distanceSlider.value = Float(UserPrefs.getTimeOffset())
        distanceLabel.text = String(UserPrefs.getTimeOffset())
        
        
    }
}

// MARK: - Time Offset

extension SettingsTableViewController {
    
}
