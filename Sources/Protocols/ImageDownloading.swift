//
//  ImageDownloading.swift
//  OKImageDownloader
//
//  Created by Jordan Guggenheim on 10/22/18.
//

import Foundation

public protocol ImageDownloading: class {
    var imageCacheCapacityInBytes: Int { get }
    var urlCache: URLCache { get }
    var urlSessionConfiguration: URLSessionConfiguration { get }
    
    func download(url: URL, receiptHandler: ImageDownloaderReceiptHandling?, completionHandler: @escaping ImageDownloader.CompletionHandler)
    
    func cancel(url: URL, receipt: ImageDownloaderReceipt?)
}
