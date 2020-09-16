//
//  AttributedString.swift
//  Trainspot.App
//
//  Created by Philipp Hentschel on 16.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

extension NSMutableAttributedString {
    
    public func setAsLink(textToFind:String, linkURL:String) -> Bool {
        
        let foundRange = self.mutableString.range(of: textToFind)
        if foundRange.location != NSNotFound {
            self.addAttribute(.link, value: linkURL, range: foundRange)
            return true
        }
        return false
    }
    
}
