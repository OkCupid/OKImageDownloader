//
//  UIButtonImageDownloaderTests.swift
//  OKImageDownloader
//
//  Created by Jordan Guggenheim on 9/24/18.
//  Copyright © 2020 OkCupid. All rights reserved.
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
    
    func test_setImageUrl_itSetsTheImageDownloadReceipt() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }
        
        XCTAssertNil(button.ok.imageDownloaderReceipt)
        
        let receipt: ImageDownloaderReceipt? = button.ok.setImage(url: url, imageDownloader: imageDownloader, completionHandler: nil)
        
        XCTAssertNotNil(button.ok.imageDownloaderReceipt)
        XCTAssertEqual(button.ok.imageDownloaderReceipt, receipt)
    }

    func test_setImageUrl_whenSuccess_itNilsTheImageDownloadReceipt() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }

        XCTAssertNil(button.ok.imageDownloaderReceipt)

        let expectation = self.expectation(description: "Nil Receipt on Completion")

        button.ok.setImage(url: url, imageDownloader: imageDownloader) { (result, receipt) in
            switch result {
            case .success:
                break

            case .failure:
                XCTFail()
            }

            XCTAssertNil(self.button.ok.imageDownloaderReceipt)
            expectation.fulfill()
        }

        XCTAssertNotNil(button.ok.imageDownloaderReceipt?.url)

        wait(for: [expectation], timeout: 5)
    }

    func test_setImageUrl_whenFailure_itNilsTheImageDownloadReceipt() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), Data())
        }

        XCTAssertNil(button.ok.imageDownloaderReceipt)

        let expectation = self.expectation(description: "Nil Receipt on Completion")

        button.ok.setImage(url: url, imageDownloader: imageDownloader) { (result, receipt) in
            switch result {
            case .success:
                XCTFail()

            case .failure:
                break
            }

            XCTAssertNil(self.button.ok.imageDownloaderReceipt)
            expectation.fulfill()
        }

        XCTAssertNotNil(button.ok.imageDownloaderReceipt?.url)

        wait(for: [expectation], timeout: 5)
    }

    func test_cancelDownload_itSetsTheReceiptNil() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }

        XCTAssertNil(button.ok.imageDownloaderReceipt)

        button.ok.setImage(url: url, imageDownloader: imageDownloader, completionHandler: nil)

        XCTAssertNotNil(button.ok.imageDownloaderReceipt)

        button.ok.cancelImageDownload()

        XCTAssertNil(button.ok.imageDownloaderReceipt)
    }
    
    func test_setImageUrl_whenSuccessAndCompletionHandler_itForwardsCompletionHandler() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }
        
        let expectation = XCTestExpectation(description: "Image Downloader UIButton Success Response")
        
        let completionHandler: ImageDownloader.CompletionHandler = { result, _ in
            switch result {
            case .success(let image):
                XCTAssertNotNil(image)
            
            case .failure:
                XCTFail()
            }
            
            expectation.fulfill()
        }
        
        button.ok.setImage(url: url, imageDownloader: imageDownloader, completionHandler: completionHandler)
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_setImageUrl_whenFailureAndCompletionHandler_itForwardsCompletionHandler() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), Data())
        }
        
        let expectation = XCTestExpectation(description: "Image Downloader UIButton Success Response")
        
        let completionHandler: ImageDownloader.CompletionHandler = { result, _ in
            switch result {
            case .success:
                XCTFail()
                
            case .failure(let error):
                XCTAssertEqual(error, .dataInvalid)
            }
            
            expectation.fulfill()
        }
        
        button.ok.setImage(url: url, imageDownloader: imageDownloader, completionHandler: completionHandler)
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_setImageUrl_whenSuccessAndNoCompletionHandler_itSetsTheImageForState() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }
        
        XCTAssertNil(button.imageView?.image)
        
        button.ok.setImage(url: url, imageDownloader: imageDownloader, completionHandler: nil)
        
        let expectation = XCTestExpectation(description: "Image Downloader UIButton Success Response")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + MockAsyncUrlProtocol.deadline + 0.1) {
            XCTAssertNotNil(self.button.image(for: .normal))
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_setImageUrl_whenFailureAndNoCompletionHandler_itDoesNotSetTheImage() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), Data())
        }
        
        let expectation = XCTestExpectation(description: "Image Downloader UIImageView Failure Response")
        
        button.ok.setImage(url: url, imageDownloader: imageDownloader, completionHandler: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + MockAsyncUrlProtocol.deadline + 0.1) {
            XCTAssertNil(self.button.imageView?.image)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20)
    }

    func test_setImageUrl_whenNil_itCancelsTheImageDownloadButLeavesTheImage() {
        MockUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }

        XCTAssertNil(button.ok.imageDownloaderReceipt)

        let mockImageDownloader: MockImageDownloader = .init()

        button.ok.setImage(url: url, imageDownloader: mockImageDownloader, completionHandler: nil)

        button.imageView?.image = expectedImage

        XCTAssertNotNil(button.ok.imageDownloaderReceipt)
        XCTAssertEqual(mockImageDownloader.cancelCallCount, 0)

        button.ok.setImage(url: nil, imageDownloader: mockImageDownloader)

        XCTAssertNil(button.ok.imageDownloaderReceipt)
        XCTAssertEqual(mockImageDownloader.cancelCallCount, 1)
        XCTAssertNotNil(button.imageView?.image)
    }

    func test_imageUrl_whenNilUrl_itCancelsTheDownload() {
        XCTAssertNil(button.ok.imageDownloaderReceipt)

        button.ok.imageUrl = url

        XCTAssertNotNil(button.ok.imageDownloaderReceipt)
        XCTAssertEqual(button.ok.imageUrl, url)

        button.ok.imageUrl = nil

        XCTAssertNil(button.ok.imageDownloaderReceipt)
    }
}
