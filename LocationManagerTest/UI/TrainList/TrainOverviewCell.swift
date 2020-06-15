//
//  TrainOverviewCell.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 09.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import UIKit

class TrainOverviewCell: UITableViewCell {


    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var arrival: UILabel!
    @IBOutlet weak var distance: UILabel!
    
    
    override func awakeFromNib() {
        self.name.layer.cornerRadius = 8
    }
}
