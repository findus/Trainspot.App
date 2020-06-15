//
//  StatusView.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 10.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import UIKit
import TripVisualizer

class StatusView : UIStackView {
    
    @IBOutlet weak var lineName: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var to: UILabel!
    @IBOutlet weak var delay: UILabel!
    private var showsDestination: Bool = false
    
    private var destination: String = "" {
        didSet {
            if !self.showsDestination {
                self.to.text = destination
            }
        }
    }
    
    private var journeyInfo: String? = "" {
        didSet {
            if self.showsDestination {
                self.to.text = journeyInfo
            }
        }
    }
    
    var counter = 0
    
    public func startTimer() {
        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(crossOverAnimation), userInfo: nil, repeats: true)
    }
    
    public func setStatus(forTrip trip: Trip, andData data: TripData) {
        
        self.journeyInfo = {
            switch data.state {
            case .Driving(let nextStop):
                return "Next Stop: \(nextStop ?? "Hell")"
            case .WaitForStart(let start):
                let formatted = secondsToHoursMinutesSeconds(seconds: Int(start))
                return "Departs in \(String(format: "%02d:%02d:%02d",formatted.0, formatted.1, formatted.2))"
            case .Stopped(let date):
                return "Departs in \(Int(date.timeIntervalSince(Date())))s"
            case .Ended:
                return "Ended"
            default:
                return nil
            }
        }()

        let delay = trip.delay ?? 0
        
        self.lineName.text = trip.name
        self.destination = "To: \(trip.destination)"
        self.distance.text = String(Int((data.distance ?? 0.0)))+String(" Meter")
        let timeFractions = secondsToHoursMinutesSeconds(seconds: Int(data.arrival))
        self.time.text = String(format: "%@%02d:%02d:%02d",timeFractions.3 ? "- " : "", timeFractions.0, timeFractions.1,timeFractions.2)
        if delay > 0 {
            self.delay.layer.cornerRadius=8.0;
            self.delay.clipsToBounds = true;
            self.delay.backgroundColor = .red
            self.delay.text = "+"+String(Int(delay / 60))
        }
        else {
            self.delay.text = String(delay)
            self.delay.backgroundColor = nil
        }

    }
    
    @objc private func crossOverAnimation() {
        
        UIView.transition(with: self.to,
             duration: 0.5,
              options: .transitionCrossDissolve,
           animations: {
            self.to.text = !self.showsDestination && self.journeyInfo != nil ? self.journeyInfo : self.destination
            self.showsDestination = !self.showsDestination
        }, completion: nil)
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int, Bool) {
        if seconds > 0 {
            return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60, false)
            
        } else {
            return ((seconds / 3600) * -1 , ((seconds % 3600) / 60) * -1, ((seconds % 3600) % 60) * -1, true)
        }
    }
}
