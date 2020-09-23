//
//  UIButton+ImageDownloader.swift
//  OkImageDownloader
//
//  Created by Jordan Guggenheim on 9/23/20.
//  Copyright © 2020 OkCupid. All rights reserved.
//

import UIKit

public extension ObjectWrapper where T: UIButton {
    
    func downloadImage(with url: URL, for state: UIControl.State = .normal, imageDownloader: ImageDownloading = ImageDownloader.shared, completionHandler: ImageDownloader.CompletionHandler? = nil) {
        cancelImageDownload()
        
        imageDownloader.download(url: url, receiptHandler: self) { dataResponse, downloadReceipt in
            guard let completionHandler = completionHandler else {
                switch dataResponse {
                case let .success(image):
                    DispatchQueue.executeAsyncOnMain {
                        self.object.setImage(image, for: state)
                    }
                    
                case .failure:
                    break
                }
                
                return
            }
            
            completionHandler(dataResponse, downloadReceipt)
        }
    }
    
}

extension UIButton: OKImageDownloaderCompatible {}
