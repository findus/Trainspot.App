//
//  DateUtils.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 07.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

func formatHafasDate(fromString string: String?) -> Date? {
    let dateFormatterGet = DateFormatter()
    dateFormatterGet.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    
    guard let string = string else {
        return nil
    }
    
    return dateFormatterGet.date(from: string)
}
