//
//  UIImageViewImageDownloaderTests.swift
//  OKImageDownloader
//
//  Created by Jordan Guggenheim on 9/24/18.
//  Copyright © 2020 OkCupid. All rights reserved.
//

import XCTest
@testable import OKImageDownloader

final class UIImageViewImageDownloaderTests: XCTestCase {
    
    private var imageDownloader: ImageDownloader!
    private let notificationCenter = NotificationCenter()
    private lazy var expectedImage = UIImage(named: "OkCupid App Icon", in: .module, compatibleWith: nil)!
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
    
    func test_downloadImage_itSetsTheImageDownloadReceipt() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }
        
        XCTAssertNil(imageView.ok.imageDownloaderReceipt?.url)
        
        imageView.ok.downloadImage(with: url, imageDownloader: imageDownloader, completionHandler: nil)
        
        XCTAssertNotNil(imageView.ok.imageDownloaderReceipt?.url)
    }
    
    func test_downloadImage_whenSuccessAndCompletionHandler_itForwardsCompletionHandler() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }
        
        let expectation = XCTestExpectation(description: "Image Downloader UIImageView Success Response")
        
        let completionHandler: ImageDownloader.CompletionHandler = { result, _ in
            switch result {
            case .success(let actualImage):
                XCTAssertNotNil(actualImage)
                
            case .failure:
                XCTFail()
            }
            
            expectation.fulfill()
        }
        
        imageView.ok.downloadImage(with: url, imageDownloader: imageDownloader, completionHandler: completionHandler)
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_downloadImage_whenFailureAndCompletionHandler_itForwardsCompletionHandler() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), Data())
        }
        
        let expectation = XCTestExpectation(description: "Image Downloader UIImageView Success Response")
        
        let completionHandler: ImageDownloader.CompletionHandler = { result, _ in
            switch result {
            case .success:
                XCTFail()
                
            case .failure(let error):
                XCTAssertEqual(error, .dataInvalid)
            }
            
            expectation.fulfill()
        }
        
        imageView.ok.downloadImage(with: url, imageDownloader: imageDownloader, completionHandler: completionHandler)
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_downloadImage_whenSuccessAndNoCompletionHandler_itSetsTheImage() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }
        
        XCTAssertNil(imageView.image)
        
        imageView.ok.downloadImage(with: url, imageDownloader: imageDownloader, completionHandler: nil)
        
        let expectation = XCTestExpectation(description: "Image Downloader UIImageView Success Response")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + MockAsyncUrlProtocol.deadline + 0.1) {
            XCTAssertNotNil(self.imageView.image)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_downloadImage_whenFailureAndNoCompletionHandler_itDoesNotSetTheImage() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), Data())
        }
        
        let expectation = XCTestExpectation(description: "Image Downloader UIImageView Failure Response")
        
        imageView.ok.downloadImage(with: url, imageDownloader: imageDownloader, completionHandler: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + MockAsyncUrlProtocol.deadline + 0.1) {
            XCTAssertNil(self.imageView.image)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_downloadImage_itCancelsCurrentReceiptAndReplacesIt() {
        let mockDownloader: MockImageDownloader = .init()
        let testReceipt: ImageDownloaderReceipt = .init(id: .init(), url: url)
        
        XCTAssertNil(imageView.ok.imageDownloaderReceipt)
        imageView.ok.imageDownloaderReceipt = testReceipt
        XCTAssertEqual(mockDownloader.downloadCallCount, 0)
        XCTAssertEqual(mockDownloader.cancelCallCount, 0)
        
        imageView.ok.downloadImage(with: url, imageDownloader: mockDownloader, completionHandler: nil)
        
        XCTAssertEqual(mockDownloader.downloadCallCount, 1)
        XCTAssertEqual(mockDownloader.cancelCallCount, 1)
        
        XCTAssertNotNil(imageView.ok.imageDownloaderReceipt)
        XCTAssertEqual(imageView.ok.imageDownloaderReceipt?.url, testReceipt.url)
        XCTAssertNotEqual(imageView.ok.imageDownloaderReceipt?.id, testReceipt.id)
    }
    
}
