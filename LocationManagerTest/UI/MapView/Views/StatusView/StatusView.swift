//
//  StatusView.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 10.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class StatusView : UIView {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var x: UILabel!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @IBInspectable
    var segments: [String] = ["One", "Two", "..."]
    
    public func setValues(forName name: String, andTime time: String, andDistance distance: String) {
        self.name.text = name
        self.time.text = time
        self.distance.text = distance
    }
}

