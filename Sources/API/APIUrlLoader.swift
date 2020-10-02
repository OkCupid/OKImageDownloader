//
//  APIUrlLoader.swift
//  OKImageDownloader
//
//  Created by Jordan Guggenheim on 9/19/18.
//

import Foundation

final class APIUrlLoader<T: APIRequest> {
    
    let apiRequest: T
    let urlSession: URLSession
    
    private var task: URLSessionDataTask?
    
    init(apiRequest: T, urlSession: URLSession) {
        self.apiRequest = apiRequest
        self.urlSession = urlSession
    }
    
    func load(completionHandler: @escaping ((T.ResponseDataType?, ImageDownloaderError?) -> Void)) {
        task = urlSession.dataTask(with: apiRequest.url) { (data, response, error) in
            if let error = (error as NSError?) {
                return completionHandler(nil, ImageDownloaderError.error(error))
            }
            
            guard let data = data else {
                return completionHandler(nil, ImageDownloaderError.dataMissing)
            }
            
            do {
                let parsedResponse: T.ResponseDataType? = try self.apiRequest.parseResponse(data: data)
                completionHandler(parsedResponse, nil)
                
            } catch {
                completionHandler(nil, error as? ImageDownloaderError)
            }
        }
        
        task?.resume()
    }
    
    func cancel() {
        task?.cancel()
    }
    
}
