//
//  MockUrlProtocol.swift
//  OKImageDownloader
//
//  Created by Jordan Guggenheim on 9/20/18.
//  Copyright © 2020 OkCupid. All rights reserved.
//

import Foundation
import XCTest

final class MockUrlProtocol: URLProtocol {
    
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let requestHandler = MockUrlProtocol.requestHandler else {
            XCTFail("received unexpected request with no handler set")
            return
        }
        
        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
            
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
        
    }
    
}
