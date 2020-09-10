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
    
    @IBOutlet weak var timeOffsetSlider: UISlider!
    @IBOutlet weak var timeOffsetLabel: UILabel!
    
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
    
    
    
    
}

// MARK: - Lifecycle

extension SettingsTableViewController {
    override func viewDidLoad() {
        Log.info("Setup setting view...")
        timeOffsetSlider.maximumValue = 100
        timeOffsetSlider.minimumValue = 0
        
        timeOffsetSlider.value = Float(UserPrefs.getTimeOffset())
        timeOffsetLabel.text = String(UserPrefs.getTimeOffset())
        
        self.dismissKey()
    
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Time Offset

extension SettingsTableViewController {
    
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
