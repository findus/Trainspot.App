//
//  Collection.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 12.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

/**
 Convenience method to check if an entry exists at a specific index of a collection without crashing the app
 */
extension Collection where Indices.Iterator.Element == Index {
    subscript (exist index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
