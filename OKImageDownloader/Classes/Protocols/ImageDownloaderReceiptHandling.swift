//
//  ImageDownloaderReceiptHandling.swift
//  OKImageDownloader
//
//  Created by Jordan Guggenheim on 10/25/18.
//

import Foundation

public protocol ImageDownloaderReceiptHandling: class {
    var imageDownloaderReceipt: ImageDownloaderReceipt? { get set }
}
