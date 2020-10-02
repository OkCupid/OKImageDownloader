//
//  ImageDownloading.swift
//  OKImageDownloader
//
//  Created by Jordan Guggenheim on 10/22/18.
//

import UIKit

public protocol ImageDownloading: class {
    var imageMemoryCacheCapacityInBytes: Int { get }
    var urlCache: URLCache { get }
    var urlSessionConfiguration: URLSessionConfiguration { get }
    
    func download(url: URL, receiptHandler: ImageDownloaderReceiptHandling?, completionHandler: @escaping ImageDownloader.CompletionHandler)
    func cachedImage(url: URL) -> UIImage?
    func cancel(url: URL, receipt: ImageDownloaderReceipt?)
}
