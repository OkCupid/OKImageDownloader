//
//  ImageDownloaderReceipt.swift
//  OkCupid
//
//  Created by Jordan Guggenheim on 9/4/18.
//  Copyright © 2020 OkCupid. All rights reserved.
//

import Foundation

public struct ImageDownloaderReceipt: Hashable, Equatable {
    let id: UUID
    let url: URL
}
