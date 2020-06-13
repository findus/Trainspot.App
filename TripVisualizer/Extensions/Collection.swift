//
//  Collection.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 12.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

extension Collection where Indices.Iterator.Element == Index {
    subscript (exist index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
