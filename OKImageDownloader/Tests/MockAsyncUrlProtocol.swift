//
//  MockAsyncUrlProtocol.swift
//  OKImageDownloader_Example
//
//  Created by Jordan Guggenheim on 9/24/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import XCTest

final class MockAsyncUrlProtocol: URLProtocol {
    
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    static var deadline: TimeInterval = 1
       
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let requestHandler = MockAsyncUrlProtocol.requestHandler else {
            XCTFail("received unexpected request with no handler set")
            return
        }
        
        do {
            let (response, data) = try requestHandler(request)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + MockAsyncUrlProtocol.deadline) {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                self.client?.urlProtocol(self, didLoad: data)
                self.client?.urlProtocolDidFinishLoading(self)
            }
            
            
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
        
    }
    
}
