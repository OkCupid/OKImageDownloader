//
//  ImageDownloaderRequestTests.swift
//  OKImageDownloader
//
//  Created by Jordan Guggenheim on 9/20/18.
//  Copyright © 2020 OkCupid. All rights reserved.
//

import XCTest
@testable import OKImageDownloader

final class ImageDownloaderTests: XCTestCase {
    
    private var imageDownloader: ImageDownloader!
    private let notificationCenter = NotificationCenter()
    private lazy var expectedImage = UIImage(named: "OkCupid App Icon", in: .module, compatibleWith: nil)!
    private lazy var expectedImageData = expectedImage.jpegData(compressionQuality: 0)!
    private let url = URL(string: "https://www.test.com")!
    
    private var receipt: ImageDownloaderReceipt {
        return ImageDownloaderReceipt(id: UUID(), url: url)
    }
    
    private var completionHandler: ImageDownloader.CompletionHandler {
        return { _, _ in }
    }
    
    override func setUp() {
        super.setUp()
        
        imageDownloader = ImageDownloader(notificationCenter: notificationCenter)
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockAsyncUrlProtocol.self]
        imageDownloader.session = URLSession(configuration: configuration)
    }
    
    override func tearDown() {
        super.tearDown()
        
        MockAsyncUrlProtocol.deadline = 1
    }
    
    func test_imageMemoryCacheCapacityInBytes_itSetsTheDefault() {
        XCTAssertEqual(imageDownloader.imageMemoryCacheCapacityInBytes, 41943040)
    }
    
    func test_imageMemoryCacheCapacityInBytes_whenSet_itUpdatesimageMemoryCacheTotalCostLimit() {
        imageDownloader.imageMemoryCacheCapacityInBytes = 40
        XCTAssertEqual(imageDownloader.imageMemoryCache.totalCostLimit, 40)
    }
    
    func test_urlSessionConfiguration_itSetsTheCachePolicy() {
        XCTAssertEqual(imageDownloader.urlSessionConfiguration.requestCachePolicy, .returnCacheDataElseLoad)
    }
    
    func test_urlSessionConfiguration_itSetsTheURLCache() {
        XCTAssertTrue(imageDownloader.urlSessionConfiguration.urlCache === imageDownloader.urlCache)
    }
    
    func test_imageMemoryCache_itSetsTheDefaultTotalCostLimit() {
        XCTAssertEqual(imageDownloader.imageMemoryCache.totalCostLimit, 41943040)
    }
    
    func test_download_whenImageIsInCache_itReturnsImage() {
        let cachableContainer = CachableContainer<UIImage>(object: expectedImage)
        imageDownloader.imageMemoryCache.setObject(cachableContainer, forKey: url as NSURL)
        
        let expectation = XCTestExpectation(description: "Image Downloader Success Response")
        
        let completionHandler: ImageDownloader.CompletionHandler = { result, _ in
            switch result {
            case .success(let actualImage):
                XCTAssertEqual(actualImage, self.expectedImage)
                
            case .failure:
                XCTFail()
            }
            
            expectation.fulfill()
        }
        
        imageDownloader.download(url: url, completionHandler: completionHandler)
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_download_whenCurrentLoaderForUrl_itAppendsTheCompletionHandlerAndCallsBoth() {
        let expectation = XCTestExpectation(description: "Image Downloader Success")
        
        MockAsyncUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }
        
        // No handlers
        XCTAssertEqual(imageDownloader.activeCompletionHandlers(for: url), 0)
        
        var actualClosureCallCount = 0
        let expectedClosureCallCount = 2
        
        let firstCompletionHandler: ImageDownloader.CompletionHandler = { _, _ in
            actualClosureCallCount += 1
            
            if actualClosureCallCount == expectedClosureCallCount {
                expectation.fulfill()
            }
        }
        
        let secondCompletionHandler: ImageDownloader.CompletionHandler = { _, _ in
            actualClosureCallCount += 1
            
            if actualClosureCallCount == expectedClosureCallCount {
                expectation.fulfill()
            }
        }
        
        imageDownloader.download(url: url, completionHandler: firstCompletionHandler)
        
        // One handler
        XCTAssertEqual(imageDownloader.activeCompletionHandlers(for: url), 1)
        
        imageDownloader.download(url: url, completionHandler: secondCompletionHandler)
        
        // Two handlers
        XCTAssertEqual(imageDownloader.activeCompletionHandlers(for: url), 2)
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_download_whenNoCurrentLoaderForUrl_itCreatesTheLoaderAndCallsCompletionUponFinish() {
        let expectation = XCTestExpectation(description: "Image Downloader Image Success")
        
        MockAsyncUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }
        
        MockAsyncUrlProtocol.deadline = 0
        
        // No loaders
        XCTAssertNil(imageDownloader.currentLoaders[url])
        
        let completionHandler: ImageDownloader.CompletionHandler = { result, _ in
            switch result {
            case .success:
                XCTAssertNotNil(self.imageDownloader.imageMemoryCache.object(forKey: self.url as NSURL))
                
            case .failure:
                XCTFail()
            }
            
            expectation.fulfill()
        }
        
        imageDownloader.download(url: url, completionHandler: completionHandler)

        // Loader with correct URL
        XCTAssertEqual(imageDownloader.currentLoaders[url]?.apiRequest.url, url)
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_download_whenComplete_itClearsActiveLoaderAndCompletionHandlers() {
        let expectation = XCTestExpectation(description: "Image Downloader Image Success")
        
        MockAsyncUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }
        
        MockAsyncUrlProtocol.deadline = 0
        
        let completionHandler: ImageDownloader.CompletionHandler = { result, _ in
            switch result {
            case .success:
                XCTAssertNil(self.imageDownloader.currentLoaders[self.url])
                XCTAssertNil(self.imageDownloader.currentCompletionHandlers[self.url])
                
            case .failure:
                XCTFail()
            }
            
            expectation.fulfill()
        }
        
        imageDownloader.download(url: url, completionHandler: completionHandler)
        
        // Loader with correct URL
        XCTAssertEqual(imageDownloader.currentLoaders[url]?.apiRequest.url, url)
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_download_whenInvalidData_itCallsCompletionUponFinish() {
        let expectation = XCTestExpectation(description: "Image Downloader Image Success")
        
        MockAsyncUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), Data())
        }
        
        MockAsyncUrlProtocol.deadline = 0
        
        let completionHandler: ImageDownloader.CompletionHandler = { result, _ in
            switch result {
            case .success:
                XCTFail()
                
            case .failure(let error):
                XCTAssertEqual(error, .dataInvalid)
            }
            
            expectation.fulfill()
        }
        
        imageDownloader.download(url: url, completionHandler: completionHandler)
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_cancel_itCallsCompletionUponCancel() {
        let expectation = XCTestExpectation(description: "Image Downloader Image Success")
        
        MockAsyncUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), Data())
        }
        
        MockAsyncUrlProtocol.deadline = 0
        
        let completionHandler: ImageDownloader.CompletionHandler = { result, _ in
            switch result {
            case .success:
                XCTFail()
                
            case .failure(let error):
                XCTAssertEqual(error, .cancelled)
            }
            
            expectation.fulfill()
        }
        
        imageDownloader.download(url: url, completionHandler: completionHandler)
        imageDownloader.cancel(url: url)
        
        wait(for: [expectation], timeout: 20)
    }
    
    func test_cancel_whenOnlyOneReceiptIsCancelled_itCallsCompletionUponCancelAndSuccess() {
        MockAsyncUrlProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, self.url)
            return (HTTPURLResponse(), self.expectedImageData)
        }
        
        MockAsyncUrlProtocol.deadline = 0
        
        let expectation = XCTestExpectation(description: "Image Downloader Image Success")
        
        var actualClosureCallCount = 0
        let expectedClosureCallCount = 2
        
        let firstCompletionHandler: ImageDownloader.CompletionHandler = { [weak self] result, _ in
            guard let self = self else { return XCTFail() }
            
            switch result {
            case .success:
                XCTFail()
                
            case .failure(let error):
                XCTAssertEqual(error, .cancelled)
                XCTAssertNotNil(self.imageDownloader.currentLoaders[self.url])
            }
            
            actualClosureCallCount += 1
            
            if actualClosureCallCount == expectedClosureCallCount {
                expectation.fulfill()
            }
        }
        
        let secondCompletionHandler: ImageDownloader.CompletionHandler = { [weak self] result, _ in
            guard let self = self else { return XCTFail() }
            
            switch result {
            case .success:
                XCTAssertNil(self.imageDownloader.currentLoaders[self.url])
                
            case .failure:
                XCTFail()
            }
            
            actualClosureCallCount += 1
            
            if actualClosureCallCount == expectedClosureCallCount {
                expectation.fulfill()
            }
        }
        
        let imageViewOne = UIImageView()
        let imageViewTwo = UIImageView()
        
        imageDownloader.download(url: url, receiptHandler: imageViewOne.ok, completionHandler: firstCompletionHandler)
        imageDownloader.download(url: url, receiptHandler: imageViewTwo.ok, completionHandler: secondCompletionHandler)
        
        XCTAssertNotEqual(imageViewOne.ok.imageDownloaderReceipt, imageViewTwo.ok.imageDownloaderReceipt)
        
        imageDownloader.cancel(url: url, receipt: imageViewOne.ok.imageDownloaderReceipt)
        
        wait(for: [expectation], timeout: 20)
    }

    func test_didReceiveMemoryWarning_itClearsTheimageMemoryCache() {
        let cachableContainer = CachableContainer<UIImage>(object: expectedImage)
        imageDownloader.imageMemoryCache.setObject(cachableContainer, forKey: url as NSURL)
        
        XCTAssertNotNil(imageDownloader.imageMemoryCache.object(forKey: url as NSURL))
        
        notificationCenter.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        XCTAssertNil(imageDownloader.imageMemoryCache.object(forKey: url as NSURL))
    }
    
    func test_activeCompletionHandlers_whenNoHandlers_itReturnsZero() {
        imageDownloader.currentCompletionHandlers[url] = nil
        XCTAssertEqual(imageDownloader.activeCompletionHandlers(for: url), 0)
    }
    
    func test_activeCompletionHandlers_whenTwoHandlers_itReturnsTwo() {
        imageDownloader.currentCompletionHandlers[url] = [receipt: completionHandler,
                                                          receipt: completionHandler]
        XCTAssertEqual(imageDownloader.activeCompletionHandlers(for: url), 2)
    }
    
    func test_checkForCurrentLoaderInProgressAndAppendCompletionIfNeeded_whenCurrentHandler_itReturnsTrueAndAppendsCompletionHandler() {
        let firstReceipt = receipt
        let secondReceipt = receipt
        
        imageDownloader.currentLoaders[url] = APIUrlLoader(apiRequest: ImageDownloaderRequest(url: url), urlSession: imageDownloader.session)
        imageDownloader.currentCompletionHandlers[url] = [firstReceipt: completionHandler]
        let isCurrentLoaderInProgress = imageDownloader.checkForCurrentLoaderInProgressAndAppendCompletionIfNeeded(with: url, receipt: secondReceipt, completionHandler: completionHandler)

        XCTAssertTrue(isCurrentLoaderInProgress)
        XCTAssertNotNil(imageDownloader.currentCompletionHandlers[url]?[firstReceipt])
        XCTAssertNotNil(imageDownloader.currentCompletionHandlers[url]?[secondReceipt])
    }
    
    func test_checkForCurrentLoaderInProgressAndAppendCompletionIfNeeded_whenNoCurrentHandler_itReturnsFalseSetsCompletionHandler() {
        let firstReceipt = receipt
        
        imageDownloader.currentLoaders[url] = APIUrlLoader(apiRequest: ImageDownloaderRequest(url: url), urlSession: imageDownloader.session)
        imageDownloader.currentCompletionHandlers[url] = [:]
        let isCurrentLoaderInProgress = imageDownloader.checkForCurrentLoaderInProgressAndAppendCompletionIfNeeded(with: url, receipt: firstReceipt, completionHandler: completionHandler)
        
        XCTAssertTrue(isCurrentLoaderInProgress)
        XCTAssertNotNil(imageDownloader.currentCompletionHandlers[url]?[firstReceipt])
    }
    
    func test_checkForCurrentLoaderInProgressAndAppendCompletionIfNeeded_whenNoCurrentLoader_itReturnsFalseAndDoesNotSetCompletionHandler() {
        let firstReceipt = receipt
        
        let isCurrentLoaderInProgress = imageDownloader.checkForCurrentLoaderInProgressAndAppendCompletionIfNeeded(with: url, receipt: firstReceipt, completionHandler: completionHandler)
        
        XCTAssertFalse(isCurrentLoaderInProgress)
        XCTAssertNil(imageDownloader.currentCompletionHandlers[url]?[firstReceipt])
    }
    
    func test_checkForImageInCacheAndCompleteIfNeeded_whenCachedImage_itReturnsTrueAndFiresCompletionHandler() {
        let cachableContainer = CachableContainer<UIImage>(object: expectedImage)
        imageDownloader.imageMemoryCache.setObject(cachableContainer, forKey: url as NSURL)
        
        let expectation = XCTestExpectation(description: "Image Downloader Success Response")
        
        var isImageInCache = false
        
        let completionHandler: ImageDownloader.CompletionHandler = { result, _ in
            switch result {
            case .success(let actualImage):
                XCTAssertEqual(actualImage, self.expectedImage)
            
            case .failure:
                XCTFail()
            }
            
            expectation.fulfill()
        }
        
        isImageInCache = imageDownloader.checkForImageInCacheAndCompleteIfNeeded(with: url, receipt: receipt, completionHandler: completionHandler)
        
        XCTAssertTrue(isImageInCache)
    }
    
    func test_checkForImageInCacheAndCompleteIfNeeded_whenNoCachedImage_itReturnsFalseAndDoesNotFireCompletionHandler() {
        let completionHandler: ImageDownloader.CompletionHandler = { response, _ in
            XCTFail()
        }
        
        let isImageInCache = imageDownloader.checkForImageInCacheAndCompleteIfNeeded(with: url, receipt: receipt, completionHandler: completionHandler)
        
        XCTAssertFalse(isImageInCache)
    }
    
    func test_complete_whenReceiptProvided_itOnlyFireCompletionHandlerForReceipt() {
        let expectation = XCTestExpectation(description: "Image Downloader Cancel Response")
        
        let receiptToCancel = receipt
        let cancelCompletionHandler: ImageDownloader.CompletionHandler = { _, _ in
            XCTAssertNil(self.imageDownloader.currentCompletionHandlers[self.url]?[receiptToCancel])
            XCTAssertEqual(self.imageDownloader.activeCompletionHandlers(for: self.url), 1)
            
            expectation.fulfill()
        }
        
        imageDownloader.currentCompletionHandlers[url] = [receiptToCancel: cancelCompletionHandler,
                                                          receipt: completionHandler]
        
        XCTAssertEqual(imageDownloader.activeCompletionHandlers(for: self.url), 2)
        
        imageDownloader.complete(url: url, receipt: receiptToCancel, result: .failure(.cancelled))
        wait(for: [expectation], timeout: 20)
    }
    
    func test_complete_whenNoReceiptProvided_itFiresCompletionHandlersAndClearsLoadersAndCompletionHandlers() {
        let expectation = XCTestExpectation(description: "Image Downloader Success Response")
        
        let firstCompletionHandler: ImageDownloader.CompletionHandler = { _, _ in
            XCTAssertNil(self.imageDownloader.currentCompletionHandlers[self.url])
            XCTAssertNil(self.imageDownloader.currentLoaders[self.url])
            XCTAssertEqual(self.imageDownloader.activeCompletionHandlers(for: self.url), 0)
            
            expectation.fulfill()
        }
        
        imageDownloader.currentCompletionHandlers[url] = [receipt: firstCompletionHandler,
                                                          receipt: completionHandler]
        
        XCTAssertEqual(imageDownloader.activeCompletionHandlers(for: self.url), 2)
        
        imageDownloader.complete(url: url, receipt: nil, result: .success(expectedImage))
        wait(for: [expectation], timeout: 20)
    }
    
}
