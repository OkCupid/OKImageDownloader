//
//  UIButtonImageDownloaderTests.swift
//  OKImageDownloader
//
//  Created by Jordan Guggenheim on 9/24/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import OKImageDownloader

final class UIButtonImageDownloaderTests: XCTestCase {
    
    private var imageDownloader: ImageDownloader!
    private let notificationCenter = NotificationCenter()
    private lazy var expectedImage = UIImage(named: "OkCupid App Icon", in: .module, compatibleWith: nil)!
    private lazy var expectedImageData = expectedImage.jpegData(compressionQuality: 0)!
    private let url = URL(string: "https://www.test.com")!
    private var button: UIButton!
    
    override func setUp() {
        super.setUp()
        
        imageDownloader = ImageDownloader(notificationCenter: notificationCenter)
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockUrlProtocol.self]
        imageDownloader.session = URLSession(configuration: configuration)
        
        button = UIButton(type: .custom)
    }
    
    func test_downloadImage_itSetsTheImageDownloadReceipt() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }
        
        XCTAssertNil(button.ok.imageDownloaderReceipt?.url)
        
        button.ok.downloadImage(with: url, imageDownloader: imageDownloader, completionHandler: nil)
        
        XCTAssertNotNil(button.ok.imageDownloaderReceipt?.url)
    }
    
    func test_downloadImage_whenSuccessAndCompletionHandler_itForwardsCompletionHandler() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }
        
        let expectation = XCTestExpectation(description: "Image Downloader UIButton Success Response")
        
        let completionHandler: ImageDownloader.CompletionHandler = { dataResponse, _ in
            if case let .success(actualImage) = dataResponse {
                XCTAssertNotNil(actualImage)
                
            } else {
                XCTFail()
            }
            
            expectation.fulfill()
        }
        
        button.ok.downloadImage(with: url, imageDownloader: imageDownloader, completionHandler: completionHandler)
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_downloadImage_whenFailureAndCompletionHandler_itForwardsCompletionHandler() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), Data())
        }
        
        let expectation = XCTestExpectation(description: "Image Downloader UIButton Success Response")
        
        let completionHandler: ImageDownloader.CompletionHandler = { dataResponse, _ in
            if case let .failure(error) = dataResponse {
                XCTAssertEqual(error, .dataInvalid)
                
            } else {
                XCTFail()
            }
            
            expectation.fulfill()
        }
        
        button.ok.downloadImage(with: url, imageDownloader: imageDownloader, completionHandler: completionHandler)
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_downloadImage_whenSuccessAndNoCompletionHandler_itSetsTheImageForState() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }
        
        XCTAssertNil(button.imageView?.image)
        
        button.ok.downloadImage(with: url, for: .highlighted, imageDownloader: imageDownloader, completionHandler: nil)
        
        let expectation = XCTestExpectation(description: "Image Downloader UIButton Success Response")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + MockAsyncUrlProtocol.deadline + 0.1) {
            XCTAssertNil(self.button.image(for: .normal))
            XCTAssertNotNil(self.button.image(for: .highlighted))
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_downloadImage_whenFailureAndNoCompletionHandler_itDoesNotSetTheImage() {
        button.ok.downloadImage(with: url, imageDownloader: imageDownloader, completionHandler: nil)
        
        XCTAssertNil(button.imageView?.image)
    }
    
}
