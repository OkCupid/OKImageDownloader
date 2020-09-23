//
//  ImageDownloaderReceiptHandling.swift
//  OKImageDownloader
//
//  Created by Jordan Guggenheim on 10/25/18.
//

import Foundation

public protocol ImageDownloaderReceiptHandling: AnyObject {
    var imageDownloaderReceipt: ImageDownloaderReceipt? { get set }
}
