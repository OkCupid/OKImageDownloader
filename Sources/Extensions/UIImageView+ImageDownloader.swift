//
//  UIImageView+ImageDownloader.swift
//  OkCupid
//
//  Created by Jordan Guggenheim on 9/5/18.
//  Copyright © 2018 OkCupid. All rights reserved.
//

import UIKit

public extension ObjectWrapper where T: UIImageView {
    
    func downloadImage(with url: URL, imageDownloader: ImageDownloading = ImageDownloader.shared, completionHandler: ImageDownloader.CompletionHandler?) {
        cancelDownloadImage()
        
        imageDownloader.download(url: url, receiptHandler: self) { dataResponse, downloadReceipt in
            guard let completionHandler = completionHandler else {
                switch dataResponse {
                case let .success(image):
                    DispatchQueue.executeAsyncOnMain {
                        self.object.image = image
                    }
                    
                case .failure:
                    break
                }
                
                return
            }
            
            completionHandler(dataResponse, downloadReceipt)
        }
    }
    
    func cancelDownloadImage(with url: URL, imageDownloader: ImageDownloading = ImageDownloader.shared) {
        imageDownloader.cancel(url: url, receipt: imageDownloaderReceipt)
    }
    
    func cancelDownloadImage(imageDownloader: ImageDownloading = ImageDownloader.shared) {
        guard let imageDownloaderReceipt = imageDownloaderReceipt else {
            return
        }
        
        imageDownloader.cancel(url: imageDownloaderReceipt.url, receipt: imageDownloaderReceipt)
    }
    
}

extension UIImageView: OKImageDownloaderCompatible{}
