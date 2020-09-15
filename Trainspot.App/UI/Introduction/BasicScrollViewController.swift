//
//  BasicScrollViewController.swift
//  Trainspot.App
//
//  Created by Philipp Hentschel on 15.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import UIKit

class BasicScrollViewController: UIViewController {
    
    @IBOutlet private var content: UIView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.content.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1).isActive = true
    }
}
