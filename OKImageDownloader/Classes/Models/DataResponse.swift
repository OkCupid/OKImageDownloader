//
//  DataResponse.swift
//  OkCupid
//
//  Created by Jordan Guggenheim on 8/31/18.
//  Copyright © 2018 OkCupid. All rights reserved.
//

import Foundation

public enum DataResponse<T> {
    case success(T)
    case failure(Error)
}
