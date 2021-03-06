//
//  ImageDownloaderRequestTests.swift
//  OKImageDownloader
//
//  Created by Jordan Guggenheim on 9/20/18.
//  Copyright © 2020 OkCupid. All rights reserved.
//

import XCTest
@testable import OKImageDownloader

final class ImageDownloaderRequestTests: XCTestCase {
    
    private var loader: APIUrlLoader<ImageDownloaderRequest>!
    private let url = URL(string: "https://www.popsci.com/sites/popsci.com/files/styles/655_1x_/public/images/2017/10/terrier-puppy.jpg?itok=Ppdi06hH&fc=50,50")!

    override func setUp() {
        super.setUp()

        let request = ImageDownloaderRequest(url: url)
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockUrlProtocol.self]
        
        loader = APIUrlLoader(apiRequest: request, urlSession: URLSession(configuration: configuration))
    }
    
    override func tearDown() {
        super.tearDown()
        
        MockUrlProtocol.requestHandler = nil
    }
    
    func test_load_whenValidData_itCompletesWithImage() {
        let expectedImage = UIImage(named: "OkCupid App Icon", in: .module, compatibleWith: nil)!
        let expectedImageData = expectedImage.jpegData(compressionQuality: 0)!
        
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), expectedImageData)
        }
        
        let expectation = XCTestExpectation(description: "Successful Image Response")
        
        loader.load { result in
            let actualImageData: Data
            
            switch result {
            case .success(let actualImage):
                actualImageData = actualImage.jpegData(compressionQuality: 0)!
                // Accuracy is needed as compresssing and decompressing the same image doesn't result in the same byte count 🙄
                XCTAssertEqual(Double(actualImageData.count), Double(expectedImageData.count), accuracy: 300)
                XCTAssertEqual(actualImage.size, expectedImage.size)
                
            case .failure:
                XCTFail()
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_load_whenInvalidData_itCompletesWithDataInvalidError() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), Data())
        }
        
        let expectation = XCTestExpectation(description: "Image Error Response")
        
        loader.load { result in
            switch result {
            case .success:
                XCTFail()
                
            case .failure(let error):
                XCTAssertEqual(error, .dataInvalid)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_load_whenInvalidDataAndNSError_itCompletesWithNSError() {
        let expectedNsError: NSError = .init(domain: "www.test.com", code: NSURLErrorNetworkConnectionLost, userInfo: nil)
        
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), Data())
        }
        
        MockUrlProtocol.error = expectedNsError
        
        let expectation = XCTestExpectation(description: "Image Error Response")
        
        loader.load { result in
            switch result {
            case .success:
                XCTFail()
                
            case .failure(let error):
                switch error {
                case .cancelled, .dataInvalid, .dataMissing:
                    XCTFail()
                    
                case .error(let actualNsError):
                    XCTAssertEqual(actualNsError.domain, expectedNsError.domain)
                    XCTAssertEqual(actualNsError.code, expectedNsError.code)
                }
            }
            
            MockUrlProtocol.error = nil
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20)
    }

}
