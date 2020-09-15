//
//  InitialViewController.swift
//  Trainspot.App
//
//  Created by Philipp Hentschel on 15.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import UIKit
import TripVisualizer
import CSVParser

class InitialViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
       
        if UserPrefs.getfirstOnboardingTriggered() == false {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.displayTutorial()
            }
        } else {
            TripHandler.shared.start()
            self.performSegue(withIdentifier: "main", sender: nil)
        }
        
        
    }
}

//MARK: Onboarding

extension InitialViewController: AutoCompleteDelegate {
    //TODO find somethingnicer to prevent callback hell ...
    private func displayTutorial() {
        let storyboard = UIStoryboard(name: "Introduction", bundle: nil)
        let vc = (storyboard.instantiateViewController(withIdentifier: "introduction") as! IntroductionBaseViewController)
        vc.onDone = { startDemo in
            UserPrefs.setfirstOnboardingTriggered(true)
            
            if startDemo {
                
                UserPrefs.setDemoModusActive(true)
                TripHandler.shared.setupDemo()
                TripHandler.shared.forceStart()
                let storyboard = UIStoryboard(name: "Introduction", bundle: nil)
                let vc = (storyboard.instantiateViewController(withIdentifier: "Demo") as! CloseableCallBackViewController)
                vc.onDone = { result in
                    self.performSegue(withIdentifier: "main", sender: nil)
                }
                self.present(vc, animated: true)
            } else {
                    self.triggerStationSelection()
            }
            
        }
        self.present(vc, animated: true)
        
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
        self.performSegue(withIdentifier: "main", sender: nil)
    }
    
    
}
