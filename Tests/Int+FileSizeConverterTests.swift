//
//  Int+FileSizeConverterTests.swift
//  OKImageDownloader
//
//  Created by Jordan Guggenheim on 9/24/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import OKImageDownloader

final class IntFileSizeConverterTests: XCTestCase {
    
    func test_megabytesInBytes() {
        XCTAssertEqual(10.megabytesInBytes, 10485760)
    }
    
}
