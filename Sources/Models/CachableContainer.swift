//
//  CachableContainer.swift
//  OkCupid
//
//  Created by Jordan Guggenheim on 8/31/18.
//  Copyright © 2018 OkCupid. All rights reserved.
//

import Foundation

public final class CachableContainer<T>: NSDiscardableContent {
    
    public let object: T
    
    public init(object: T) {
        self.object = object
    }
    
    // MARK: - NSDiscardableContent
    
    public func beginContentAccess() -> Bool {
        return true
    }
    
    public func endContentAccess() {}
    
    public func discardContentIfPossible() {}
    
    public func isContentDiscarded() -> Bool {
        return false
    }
}
