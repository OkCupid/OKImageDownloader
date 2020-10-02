//
//  ImageDownloaderError.swift
//  OkImageDownloader
//
//  Created by Jordan Guggenheim on 8/28/18.
//  Copyright © 2018 Jordan Guggenheim. All rights reserved.
//

import Foundation

public enum ImageDownloaderError: Error, Equatable {
    case cancelled
    case dataInvalid
    case dataMissing
    case error(NSError)
}
