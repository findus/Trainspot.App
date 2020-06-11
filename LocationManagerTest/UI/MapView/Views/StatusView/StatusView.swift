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
        
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public func setValues(forName name: String, andTime time: String, andDistance distance: String, andArrivalTime arrTime: String) {
        self.name.text = name
        self.time.text = time
        self.distance.text = distance
        self.to.text = arrTime
    }
}

