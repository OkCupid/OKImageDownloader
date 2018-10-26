//
//  UIImageViewImageDownloaderTests.swift
//  OKImageDownloader_Example
//
//  Created by Jordan Guggenheim on 9/24/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import OKImageDownloader

final class UIImageViewImageDownloaderTests: XCTestCase {
    
    private var imageDownloader: ImageDownloader!
    private let notificationCenter = NotificationCenter()
    private lazy var expectedImage = UIImage(named: "OkCupid App Icon", in: Bundle(for: type(of: self)), compatibleWith: nil)!
    private lazy var expectedImageData = expectedImage.jpegData(compressionQuality: 0)!
    private let url = URL(string: "https://www.test.com")!
    private var imageView: UIImageView!
    
    override func setUp() {
        super.setUp()
        
        imageDownloader = ImageDownloader(notificationCenter: notificationCenter)
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockUrlProtocol.self]
        imageDownloader.session = URLSession(configuration: configuration)
        
        imageView = UIImageView()
    }
    
    override func tearDown() {
        super.tearDown()
        
        MockUrlProtocol.requestHandler = nil
    }
    
    func test_downloadImage_itSetsTheImageDownloadReceipt() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }
        usleep(100000)
        
        XCTAssertNil(imageView.imageDownloaderReceipt?.url)
        
        imageView.downloadImage(with: url, imageDownloader: imageDownloader, completionHandler: nil)
        
        XCTAssertNotNil(imageView.imageDownloaderReceipt?.url)
    }
    
    func test_downloadImage_whenSuccessAndCompletionHandler_itForwardsCompletionHandler() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }
        usleep(100000)
        
        let expectation = XCTestExpectation(description: "Image Downloader UIImageView Success Response")
        
        let completionHandler: ImageDownloader.CompletionHandler = { dataResponse, _ in
            if case let .success(actualImage) = dataResponse {
                XCTAssertNotNil(actualImage)
                
            } else {
                XCTFail()
            }
            
            expectation.fulfill()
        }
        
        imageView.downloadImage(with: url, imageDownloader: imageDownloader, completionHandler: completionHandler)
        
        wait(for: [expectation], timeout: 2)
    }
    
    func test_downloadImage_whenFailureAndCompletionHandler_itForwardsCompletionHandler() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), Data())
        }
        usleep(100000)
        
        let expectation = XCTestExpectation(description: "Image Downloader UIImageView Success Response")
        
        let completionHandler: ImageDownloader.CompletionHandler = { dataResponse, _ in
            if case let .failure(error) = dataResponse, let imageError = error as? ImageDownloaderError {
                XCTAssertEqual(imageError, .dataInvalid)
                
            } else {
                XCTFail()
            }
            
            expectation.fulfill()
        }
        
        imageView.downloadImage(with: url, imageDownloader: imageDownloader, completionHandler: completionHandler)
        
        wait(for: [expectation], timeout: 1)
    }
    
    func test_downloadImage_whenSuccessAndNoCompletionHandler_itSetsTheImage() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }
        usleep(100000)
        
        XCTAssertNil(imageView.image)
        
        imageView.downloadImage(with: url, imageDownloader: imageDownloader, completionHandler: nil)
        
        let expectation = XCTestExpectation(description: "Image Downloader UIImageView Success Response")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertNotNil(self.imageView.image)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func test_downloadImage_whenFailureAndNoCompletionHandler_itDoesNotSetTheImage() {
        imageView.downloadImage(with: url, imageDownloader: imageDownloader, completionHandler: nil)
        
        XCTAssertNil(imageView.image)
    }
    
}
