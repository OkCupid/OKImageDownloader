//
//  UIImageView+ImageDownloader.swift
//  OkCupid
//
//  Created by Jordan Guggenheim on 9/5/18.
//  Copyright © 2020 OkCupid. All rights reserved.
//

import UIKit

public extension ObjectWrapper where T: UIImageView {

    var imageUrl: URL? {
        get {
            imageDownloaderReceipt?.url
        }
        set {
            setImageUrl(url: newValue)
        }
    }
    
    func setImageUrl(url: URL?,
                     imageDownloader: ImageDownloading = ImageDownloader.shared,
                     completionHandler: ImageDownloader.CompletionHandler? = nil) {
        guard let url = url else {
            cancelImageDownload(imageDownloader: imageDownloader)
            return
        }
        
        if imageDownloaderReceipt != nil {
            assertionFailure("Active Download In Progress, Cancel Before Starting a New Request")
        }
        
        imageDownloader.download(url: url, receiptHandler: self) { result, downloadReceipt in
            self.imageDownloaderReceipt = nil
            
            guard let completionHandler = completionHandler else {
                switch result {
                case .success(let image):
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
    }
    
}

extension UIImageView: OKImageDownloaderCompatible {}
