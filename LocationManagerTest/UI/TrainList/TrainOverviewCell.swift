//
//  TrainOverviewCell.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 09.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import UIKit
import MarqueeLabel

class TrainOverviewCell: UITableViewCell {


    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var arrival: UILabel!
    @IBOutlet weak var info: MarqueeLabel!
    
    var counter = 1    
    
    override func awakeFromNib() {
        self.name.layer.cornerRadius = 8
        
        //Marquee
        info.type = .continuous
        info.scrollDuration = 5.0
        info.animationCurve = .linear
        info.animationDelay = 0
        info.fadeLength = 10.0
        info.leadingBuffer = 20.0
        info.trailingBuffer = 20.0
  
    }
}
