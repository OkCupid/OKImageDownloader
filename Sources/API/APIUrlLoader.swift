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
    
    func load(completionHandler: @escaping ((Result<T.ResponseDataType, ImageDownloaderError>) -> Void)) {
        task = urlSession.dataTask(with: apiRequest.url) { (data, response, error) in
            if let error = (error as NSError?) {
                return completionHandler(.failure(.error(error)))
            }
            
            guard let data = data else {
                return completionHandler(.failure(.dataMissing))
            }
            
            do {
                let parsedResponse: T.ResponseDataType = try self.apiRequest.parseResponse(data: data)
                completionHandler(.success(parsedResponse))
                
            } catch {
                if let error = error as? ImageDownloaderError {
                    return completionHandler(.failure(error))
                } else {
                    return completionHandler(.failure(.error(error as NSError)))
                }
            }
        }
        
        task?.resume()
    }
    
    func cancel() {
        task?.cancel()
    }
    
}
