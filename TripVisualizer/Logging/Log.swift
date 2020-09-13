//
//  File.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 05.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import Log

#if RELEASE
let Log = Logger(formatter: .detailed, theme: .none, minLevel: .warning)
#else
let Log = Logger(formatter: .detailed, theme: .none, minLevel: .trace)
#endif

extension Themes {
    static let tomorrowNight = Theme(
        trace:   "#C5C8C6",
        debug:   "#81A2BE",
        info:    "#B5BD68",
        warning: "#F0C674",
        error:   "#CC6666"
    )
}
