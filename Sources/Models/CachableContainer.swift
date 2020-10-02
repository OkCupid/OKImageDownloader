//
//  CachableContainer.swift
//  OkCupid
//
//  Created by Jordan Guggenheim on 8/31/18.
//  Copyright © 2018 OkCupid. All rights reserved.
//

import Foundation

final class CachableContainer<T>: NSDiscardableContent {
    
    let object: T
    
    init(object: T) {
        self.object = object
    }
    
    // MARK: - NSDiscardableContent
    
    func beginContentAccess() -> Bool {
        return true
    }
    
    func endContentAccess() {}
    
    func discardContentIfPossible() {}
    
    func isContentDiscarded() -> Bool {
        return false
    }
}
