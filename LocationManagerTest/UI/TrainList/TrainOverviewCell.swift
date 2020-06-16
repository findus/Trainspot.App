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
    @IBOutlet weak var arrival: UILabel! {
        didSet {
            arrival.font = arrival.font.monospacedDigitFont
        }
    }
    @IBOutlet weak var info: UILabel! {
        didSet {
            info.font = info.font.monospacedDigitFont
        }
    }
    
    var counter = 1
    
    override func awakeFromNib() {
        self.name.layer.cornerRadius = 8
  
    }
}
