//
//  ImageDownloaderRequest.swift
//  OKImageDownloader
//
//  Created by Jordan Guggenheim on 9/19/18.
//

import Foundation

struct ImageDownloaderRequest: APIRequest {
    
    var url: URL
    
    func parseResponse(data: Data) throws -> UIImage {
        do {
            if let image = UIImage.threadSafeImage(with: data) {
                return image
            } else {
                throw ImageDownloaderError.dataInvalid
            }
        }
    }
    
}
