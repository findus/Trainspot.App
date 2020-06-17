//
//  File.swift
//  LocationManagerTest
//
//  Created by Philipp on 17.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import UIKit
import SwiftEventBus

public class MainTabbarViewController: UITabBarController {
    
    public override func viewDidLoad() {
        self.setupEventBusListener()
    }
    
    private func setupEventBusListener() {
        SwiftEventBus.onMainThread(self, name: "selectTab") { notification in
            if let index = notification?.object as? Int {
                self.selectedIndex = index
            }
        }
    }
    
}
