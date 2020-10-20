//
//  MockImageDownloader.swift
//  OKImageDownloader
//
//  Created by Jordan Guggenheim on 9/20/18.
//  Copyright © 2020 OkCupid. All rights reserved.
//

@testable import OKImageDownloader
import XCTest

final class MockImageDownloader: ImageDownloading {
    
    var imageMemoryCacheCapacityInBytes: Int = 0
    
    var urlCache: URLCache = .init()
    
    var urlSessionConfiguration: URLSessionConfiguration = .ephemeral
    
    var downloadCallCount: Int = 0
    
    func download(url: URL, receiptHandler: ImageDownloaderReceiptHandling?, completionHandler: @escaping ImageDownloader.CompletionHandler) {
        downloadCallCount += 1
        receiptHandler?.imageDownloaderReceipt = .init(id: .init(), url: url)
    }
    
    var cachedImageCallCount: Int = 0
    
    func cachedImage(url: URL) -> UIImage? {
        cachedImageCallCount += 1
        return nil
    }
    
    var cancelCallCount: Int = 0
    
    func cancel(url: URL, receipt: ImageDownloaderReceipt?) {
        cancelCallCount += 1
    }
    
}
