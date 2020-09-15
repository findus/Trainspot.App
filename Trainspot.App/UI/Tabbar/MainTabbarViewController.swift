//
//  File.swift
//  LocationManagerTest
//
//  Created by Philipp on 17.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import UIKit
import SwiftEventBus
import TripVisualizer
import CSVParser

public class MainTabbarViewController: UITabBarController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupEventBusListener()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // if UserPrefs.getfirstOnboardingTriggered() == false {
        self.displayTutorial()
        // }
    }
    
    private func setupEventBusListener() {
        SwiftEventBus.onMainThread(self, name: "selectTab") { notification in
            if let index = notification?.object as? Int {
                self.selectedIndex = index
            }
        }
    }
    
}


//MARK: Onboarding

extension MainTabbarViewController: AutoCompleteDelegate {
    
    private func displayTutorial() {
        let storyboard = UIStoryboard(name: "Introduction", bundle: nil)
        let vc = (storyboard.instantiateViewController(withIdentifier: "introduction") as! IntroductionBaseViewController)
        vc.onDone = {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.triggerStationSelection()
            }
        }
        self.present(vc, animated: true)
        
        UserPrefs.setfirstOnboardingTriggered(true)
    }
    
    private func triggerStationSelection() {
        let controller = AutoCompleteViewController(nibName: "AutoCompleteViewController", bundle: nil)
        
        let content = CsvReader.shared.getAll()
        controller.delegate = self
        controller.data = content?.map({ (a) -> String in
            a.stationName
        })
        
        self.present(controller, animated: true, completion: nil)
    }
    
    func onValueSelected(_ value: String?) {
        
        guard let newStationName = value  else {
            return
        }
        
        Log.info("User selected \(newStationName) as new station")
        
        guard let data = CsvReader.shared.getStationInfo(withContent: newStationName)?.first?.ibnr else {
            Log.error("Could not find ibnr for station named \(newStationName)")
            return
        }
        
        let stationInfo = StationInfo(newStationName, data)
        
        UserPrefs.setSelectedStation(stationInfo)
        SwiftEventBus.post("UpdatedSettings")
    }
    
}
