//
//  OKNameSpace.swift
//  OkImageDownloader
//
//  Created by Jordan Guggenheim on 9/23/20.
//  Copyright © 2020 OkCupid. All rights reserved.
//

import UIKit

public class ObjectWrapper<T: AnyObject> {
    public let object: T
    public init(_ object: T) {
        self.object = object
    }
}

public protocol OKImageDownloaderCompatible: AnyObject {}

public extension OKImageDownloaderCompatible {
    var ok: ObjectWrapper<Self> {
        return ObjectWrapper(self)
    }
}

private struct AssociatedKey {
    static var imageDownloaderReceipt: String = "ok_UIImageView.ImageDownloaderReceipt"
}

extension ObjectWrapper: ImageDownloaderReceiptHandling {

    public var imageDownloaderReceipt: ImageDownloaderReceipt? {
        get {
            if let imageDownloaderReceipt = objc_getAssociatedObject(self.object, &AssociatedKey.imageDownloaderReceipt) as? ImageDownloaderReceipt {
                return imageDownloaderReceipt
            } else {
                return nil
            }
        }
        set {
            objc_setAssociatedObject(self.object, &AssociatedKey.imageDownloaderReceipt, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func cancelImageDownload(imageDownloader: ImageDownloading = ImageDownloader.shared) {
        guard let imageDownloaderReceipt = imageDownloaderReceipt else {
            return
        }
        
        self.imageDownloaderReceipt = nil
        imageDownloader.cancel(url: imageDownloaderReceipt.url, receipt: imageDownloaderReceipt)
    }
}

