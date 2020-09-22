//
//  Int+FileSizeConverter.swift
//  OkCupid
//
//  Created by Jordan Guggenheim on 9/6/18.
//  Copyright © 2018 OkCupid. All rights reserved.
//

import Foundation

extension Int {
    
    var megabytesInBytes: Int {
        return self * 1024 * 1024
    }
}
