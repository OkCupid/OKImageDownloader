//
//  Int+FileSizeConverter.swift
//  OkCupid
//
//  Created by Jordan Guggenheim on 9/22/20.
//  Copyright © 2020 OkCupid. All rights reserved.
//


import Foundation

extension DispatchQueue {
    
    static func executeAsyncOnMain(closure: @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async {
                closure()
            }
        }
    }
    
}
