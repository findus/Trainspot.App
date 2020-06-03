//
//  Math+Extension.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 03.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import UIKit

extension Double {
    var toRadians: CGFloat { return CGFloat(self * .pi / 180) }
    var toDegrees: CGFloat { return CGFloat(self * 180 / .pi) }
}

extension CGFloat {
    var toRadians: CGFloat { return CGFloat(self * .pi / 180) }
    var toDegrees: CGFloat { return CGFloat(self * 180 / .pi) }
}
