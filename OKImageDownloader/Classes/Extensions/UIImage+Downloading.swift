//
//  UIImage+Downloading.swift
//  OkCupid
//
//  Created by Jordan Guggenheim on 8/29/18.
//  Copyright © 2018 OkCupid. All rights reserved.
//

import UIKit

// MARK: Initialization

private let lock = NSLock()

extension UIImage {
    /// Initializes and returns the image object with the specified data in a thread-safe manner.
    ///
    /// It has been reported that there are thread-safety issues when initializing large amounts of images
    /// simultaneously. In the event of these issues occurring, this method can be used in place of
    /// the `init?(data:)` method.
    ///
    /// - parameter data: The data object containing the image data.
    ///
    /// - returns: An initialized `UIImage` object, or `nil` if the method failed.
    public static func threadSafeImage(with data: Data) -> UIImage? {
        lock.lock()
        let image = UIImage(data: data)
        lock.unlock()
        
        return image
    }
    
    
    /// Inflates the underlying compressed image data to be backed by an uncompressed bitmap representation.
    ///
    /// Inflating compressed image formats (such as PNG or JPEG) can significantly improve drawing performance as it
    /// allows a bitmap representation to be constructed in the background rather than on the main thread.
    public func inflate() {
        _ = cgImage?.dataProvider?.data
    }
}
