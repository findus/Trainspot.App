//
//  StatusView.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 10.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import UIKit

class StatusView : UIView {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var to: UILabel!
    
    var blur = false
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public func setValues(forName name: String, andTime time: String, andDistance distance: String) {
        self.name.text = name
        self.time.text = time
        self.distance.text = distance
    }
    
    override func awakeFromNib() {
        if self.blur {
            setupBlur()
        }
        self.blur = true
    }
    
    private func setupBlur() {
        let blur = UIBlurEffect(style: .regular)
        let blurEffectView = UIVisualEffectView(effect: blur)
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.insertSubview(blurEffectView, at: 0)
    }
    
}

