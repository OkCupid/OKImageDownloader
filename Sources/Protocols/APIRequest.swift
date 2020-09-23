//
//  APIRequest.swift
//  OKImageDownloader
//
//  Created by Jordan Guggenheim on 9/19/18.
//

import Foundation

protocol APIRequest {
    associatedtype ResponseDataType
    
    var url: URL { get }
    
    func parseResponse(data: Data) throws -> ResponseDataType
}
