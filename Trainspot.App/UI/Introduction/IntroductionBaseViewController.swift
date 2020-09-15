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
    
    private var startDemo = false
    @IBOutlet private var demoButton: UIButton!
    public var onDone: ((_ startDemo: Bool)->Void)? = nil
    
    @IBAction func onClose(_ sender: Any) {
        startDemo = true
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let doneCallback = onDone {
            doneCallback(startDemo)
        }
    }

}
