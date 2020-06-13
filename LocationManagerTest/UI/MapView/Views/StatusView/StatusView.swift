//
//  StatusView.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 10.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import UIKit

class StatusView : UIVisualEffectView {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var to: UILabel!
    @IBOutlet weak var delay: UILabel!
    private var showsDestination: Bool = false
    
    private var destination: String = ""
    private var nextStop: String? = ""
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public func setValues(forName name: String, andDestination destination: String, andDistance distance: String, andArrivalTime arrTime: Int, andDelay delay: Int, andNextStop nextStop: String?) {
        self.name.text = name
        self.destination = name
        self.nextStop = nextStop
        self.time.text = destination
        self.distance.text = distance
        let timeFractions = secondsToHoursMinutesSeconds(seconds: arrTime)
        self.to.text = String(format: "%@%d:%d:%d",timeFractions.3 ? "- " : "", timeFractions.0, timeFractions.1,timeFractions.2)
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
    
    override class func awakeFromNib() {
        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(crossOverAnimation), userInfo: nil, repeats: true)
    }
    
    @objc private func crossOverAnimation() {
        UIView.transition(with: self.name,
             duration: 0.25,
              options: .transitionCrossDissolve,
           animations: {
            self.name.text = !self.showsDestination && self.nextStop != nil ? self.nextStop : self.destination
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
