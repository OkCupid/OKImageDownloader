//
//  DispatchQueue+ExtensionTests.swift
//  OKImageDownloader
//
//  Created by Jordan Guggenheim on 10/20/20.
//  Copyright © 2020 OkCupid. All rights reserved.
//

import XCTest
@testable import OKImageDownloader

final class DispatchQueueExtensionTests: XCTestCase {
    
    func test_dispatchMain_whenMainThread_itReturnsOnMainThread() {
        let expectation: XCTestExpectation = self.expectation(description: "Main Thread Test")
        
        let isCurrentThreadMain: Bool = Thread.isMainThread
        let currentRunLoop: RunLoop = .current
        
        XCTAssertTrue(isCurrentThreadMain)
        
        DispatchQueue.executeAsyncOnMain {
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(currentRunLoop, .current)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }
    
    func test_dispatchMain_whenBackgroundThread_itReturnsOnMainThread() {
        let expectation: XCTestExpectation = self.expectation(description: "Background Thread Test")
        
        DispatchQueue.global().async {
            let isCurrentThreadMain: Bool = Thread.isMainThread
            let currentRunLoop: RunLoop = .current
            
            XCTAssertFalse(isCurrentThreadMain)
            
            DispatchQueue.executeAsyncOnMain {
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotEqual(currentRunLoop, .current)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2)
    }
    
}
