//
//  CachableContainerTests.swift
//  OKImageDownloader
//
//  Created by Jordan Guggenheim on 9/24/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import OKImageDownloader

final class CachableContainerTests: XCTestCase {
    
    func test_init_itSetsTheObject() {
        let object = "test"
        let container = CachableContainer(object: object)
        
        XCTAssertEqual(object, container.object)
    }
    
    func test_init_itSetsBeginContentAccessTrue() {
        let container = CachableContainer(object: "test")
        
        XCTAssertTrue(container.beginContentAccess())
    }
    
    func test_init_itSetsIsContentDiscardedFalse() {
        let container = CachableContainer(object: 1)
        
        XCTAssertFalse(container.isContentDiscarded())
    }
    
}
