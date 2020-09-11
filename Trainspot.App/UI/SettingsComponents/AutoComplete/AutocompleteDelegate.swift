//
//  AutocompleteDelegate.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 10.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

protocol AutoCompleteDelegate: class {
    func onValueSelected(_ value: String?)
}
