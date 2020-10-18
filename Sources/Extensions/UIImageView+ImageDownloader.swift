//
//  UIImageView+ImageDownloader.swift
//  OkCupid
//
//  Created by Jordan Guggenheim on 9/5/18.
//  Copyright © 2020 OkCupid. All rights reserved.
//

import UIKit

public extension ObjectWrapper where T: UIImageView {
    
    func downloadImage(with url: URL,
                       imageDownloader: ImageDownloading = ImageDownloader.shared,
                       completionHandler: ImageDownloader.CompletionHandler? = nil) {
        cancelImageDownload()
        
        imageDownloader.download(url: url, receiptHandler: self) { result, downloadReceipt in
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
