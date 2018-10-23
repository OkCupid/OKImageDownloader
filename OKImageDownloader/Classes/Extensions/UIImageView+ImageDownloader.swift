//
//  UIImageView+ImageDownloader.swift
//  OkCupid
//
//  Created by Jordan Guggenheim on 9/5/18.
//  Copyright © 2018 OkCupid. All rights reserved.
//

import Foundation

public extension UIImageView {
    
    private struct AssociatedKey {
        static var imageDownloaderReceipt = "af_UIImageView.ImageDownloaderReceipt"
    }
    
    public var imageDownloaderReceipt: ImageDownloaderReceipt? {
        get {
            if let imageDownloaderReceipt = objc_getAssociatedObject(self, &AssociatedKey.imageDownloaderReceipt) as? ImageDownloaderReceipt {
                return imageDownloaderReceipt
            } else {
                return nil
            }
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.imageDownloaderReceipt, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func downloadImage(with url: URL, imageDownloader: ImageDownloading = ImageDownloader.shared, completionHandler: ImageDownloader.CompletionHandler?) {
        imageDownloaderReceipt = imageDownloader.download(url: url) { dataResponse, downloadReceipt in
         
            guard let completionHandler = completionHandler else {
                switch dataResponse {
                case let .success(image):
                    self.image = image
                    
                case .failure:
                    break
                }
                
                return
            }
            
            completionHandler(dataResponse, downloadReceipt)
        }
    }
    
    public func cancelDownloadImage(with url: URL, imageDownloader: ImageDownloading = ImageDownloader.shared) {
        imageDownloader.cancel(url: url, receipt: imageDownloaderReceipt)
    }
    
    public func cancelDownloadImage(imageDownloader: ImageDownloading = ImageDownloader.shared) {
        guard let imageDownloaderReceipt = imageDownloaderReceipt else {
            return
        }
        
        imageDownloader.cancel(url: imageDownloaderReceipt.url, receipt: imageDownloaderReceipt)
    }
    
}
