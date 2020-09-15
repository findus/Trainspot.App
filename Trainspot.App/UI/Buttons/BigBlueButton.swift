//
//  BigBlueButton.swift
//  Trainspot.App
//
//  Created by Philipp Hentschel on 15.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
public class BigBlueButton: UIButton {
    
    @IBInspectable var bgColor: UIColor = .blue {
        didSet {
            self.backgroundColor = bgColor
        }
    }
    
    @IBInspectable var textColor: UIColor = .white {
        didSet {
            self.setTitleColor(textColor, for: .normal)
        }
    }
    
    public override func awakeFromNib() {
        self.layer.cornerRadius = 10
    }
    
}
