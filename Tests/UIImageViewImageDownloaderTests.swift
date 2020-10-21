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
    
    func test_setImage_itSetsTheImageDownloadReceipt() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }
        
        XCTAssertNil(imageView.ok.imageDownloaderReceipt?.url)
        
        imageView.ok.setImage(with: url, imageDownloader: imageDownloader, completionHandler: nil)
        
        XCTAssertNotNil(imageView.ok.imageDownloaderReceipt?.url)
    }

    func test_setImage_whenSuccess_itNilsTheImageDownloadReceipt() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }

        XCTAssertNil(imageView.ok.imageDownloaderReceipt)

        let expectation = self.expectation(description: "Nil Receipt on Completion")

        imageView.ok.setImage(with: url, imageDownloader: imageDownloader) { (result, receipt) in
            switch result {
            case .success:
                break

            case .failure:
                XCTFail()
            }

            XCTAssertNil(self.imageView.ok.imageDownloaderReceipt)
            expectation.fulfill()
        }

        XCTAssertNotNil(imageView.ok.imageDownloaderReceipt?.url)

        wait(for: [expectation], timeout: 5)
    }

    func test_setImage_whenFailure_itNilsTheImageDownloadReceipt() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), Data())
        }

        XCTAssertNil(imageView.ok.imageDownloaderReceipt)

        let expectation = self.expectation(description: "Nil Receipt on Completion")

        imageView.ok.setImage(with: url, imageDownloader: imageDownloader) { (result, receipt) in
            switch result {
            case .success:
                XCTFail()

            case .failure:
                break
            }

            XCTAssertNil(self.imageView.ok.imageDownloaderReceipt)
            expectation.fulfill()
        }

        XCTAssertNotNil(imageView.ok.imageDownloaderReceipt?.url)

        wait(for: [expectation], timeout: 5)
    }

    func test_cancelDownload_itSetsTheReceiptNil() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }

        XCTAssertNil(imageView.ok.imageDownloaderReceipt)

        imageView.ok.setImage(with: url, imageDownloader: imageDownloader, completionHandler: nil)

        XCTAssertNotNil(imageView.ok.imageDownloaderReceipt)

        imageView.ok.cancelImageDownload()

        XCTAssertNil(imageView.ok.imageDownloaderReceipt)
    }
    
    func test_setImage_whenSuccessAndCompletionHandler_itForwardsCompletionHandler() {
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
        
        imageView.ok.setImage(with: url, imageDownloader: imageDownloader, completionHandler: completionHandler)
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_setImage_whenFailureAndCompletionHandler_itForwardsCompletionHandler() {
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
        
        imageView.ok.setImage(with: url, imageDownloader: imageDownloader, completionHandler: completionHandler)
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_setImage_whenSuccessAndNoCompletionHandler_itSetsTheImage() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }
        
        XCTAssertNil(imageView.image)
        
        imageView.ok.setImage(with: url, imageDownloader: imageDownloader, completionHandler: nil)
        
        let expectation = XCTestExpectation(description: "Image Downloader UIImageView Success Response")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + MockAsyncUrlProtocol.deadline + 0.1) {
            XCTAssertNotNil(self.imageView.image)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_setImage_whenFailureAndNoCompletionHandler_itDoesNotSetTheImage() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), Data())
        }
        
        let expectation = XCTestExpectation(description: "Image Downloader UIImageView Failure Response")
        
        imageView.ok.setImage(with: url, imageDownloader: imageDownloader, completionHandler: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + MockAsyncUrlProtocol.deadline + 0.1) {
            XCTAssertNil(self.imageView.image)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20)
    }
    
}
