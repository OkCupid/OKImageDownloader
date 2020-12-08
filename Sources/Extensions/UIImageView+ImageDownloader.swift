//
//  UIImageView+ImageDownloader.swift
//  OkCupid
//
//  Created by Jordan Guggenheim on 9/5/18.
//  Copyright © 2020 OkCupid. All rights reserved.
//

import UIKit

public extension ObjectWrapper where T: UIImageView {
    
    /// A convenience property that when set will download (or cancel if nil) the url. The getter returns the active imageDownloaderReceipt URL.
    var imageUrl: URL? {
        get {
            imageDownloaderReceipt?.url
        }
        set {
            setImage(url: newValue)
        }
    }
    
    /// A convenience method to set an image based on a URL.
    /// - Parameters:
    ///   - url: the HTTP URL for the image download. If set to nil, it will cancel any active requests based on the imageDownloaderReceipt. Note: This does not currently support local file system URLs.
    ///   - imageDownloader: The Image Downloader shared instance. Used for unit testing injection of mocks.
    ///   - completionHandler: If set to nil, the image will be automatically set on completion. If completionHandler is set, the image will not be automatically set and instead returned via the completionHandler for further modifications (resizing, image filters, custom animation transitions, etc.)
    /// - Returns: The receipt for the active image download.
    @discardableResult
    func setImage(url: URL?,
                  imageDownloader: ImageDownloading = ImageDownloader.shared,
                  completionHandler: ImageDownloader.CompletionHandler? = nil) -> ImageDownloaderReceipt? {
        guard let url = url else {
            cancelImageDownload(imageDownloader: imageDownloader)
            return nil
        }
        
        if imageDownloaderReceipt != nil {
            assertionFailure("Active Download In Progress, Cancel Before Starting a New Request")
        }
        
        imageDownloader.download(url: url, receiptHandler: self) { result, downloadReceipt in
            let isDownloadCancelled: Bool = self.imageDownloaderReceipt?.url != url

            self.imageDownloaderReceipt = nil
            
            guard let completionHandler = completionHandler else {
                switch result {
                case .success(let image):
                    guard isDownloadCancelled == false else { return }

                    DispatchQueue.executeAsyncOnMain {
                        self.object.image = image
                    }
                    
                case .failure:
                    break
                }
                
                return
            }
            
            completionHandler(result, downloadReceipt)
        }
        
        return imageDownloaderReceipt
    }
    
}

extension UIImageView: OKImageDownloaderCompatible {}
