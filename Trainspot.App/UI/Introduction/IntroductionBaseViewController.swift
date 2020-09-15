//
//  IntroductionBaseViewController.swift
//  Trainspot.App
//
//  Created by Philipp Hentschel on 15.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import UIKit

class IntroductionBaseViewController: UIViewController {
    
    @IBOutlet private var closeButton: UIButton!
    public var onDone: (()->Void)? = nil
    
    @IBAction func onClose(_ sender: Any) {
        if let doneCallback = onDone {
            doneCallback()
        }
        self.dismiss(animated: true, completion: nil)
    }
}
