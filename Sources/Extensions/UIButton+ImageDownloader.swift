//
//  UIButton+ImageDownloader.swift
//  OkImageDownloader
//
//  Created by Jordan Guggenheim on 9/23/20.
//  Copyright © 2020 OkCupid. All rights reserved.
//

import UIKit

public extension ObjectWrapper where T: UIButton {
    
    func setImage(with url: URL,
                  for state: UIControl.State = .normal,
                  imageDownloader: ImageDownloading = ImageDownloader.shared,
                  completionHandler: ImageDownloader.CompletionHandler? = nil) {
        if imageDownloaderReceipt != nil {
            assertionFailure("Active Download In Progress, Cancel Before Starting a New Request")
        }
        
        imageDownloader.download(url: url, receiptHandler: self) { result, downloadReceipt in
            self.imageDownloaderReceipt = nil

            guard let completionHandler = completionHandler else {
                switch result {
                case .success(let image):
                    DispatchQueue.executeAsyncOnMain {
                        self.object.setImage(image, for: state)
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

extension UIButton: OKImageDownloaderCompatible {}
