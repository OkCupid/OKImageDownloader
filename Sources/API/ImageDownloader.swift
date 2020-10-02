//
//  ImageDownloader.swift
//  OkImageDownloader
//
//  Created by Jordan Guggenheim on 8/28/18.
//  Copyright © 2018 OkCupid. All rights reserved.
//

import UIKit

public final class ImageDownloader: ImageDownloading {
    
    // MARK: - Public Properties
    
    public typealias CompletionHandler = (_ dataResponse: Result<UIImage, ImageDownloaderError>, _ downloadReceipt: ImageDownloaderReceipt) -> Void
    public static let shared: ImageDownloader = .init()
    
    public var imageMemoryCacheCapacityInBytes: Int = 40.megabytesInBytes {
        didSet {
            imageMemoryCache.totalCostLimit = imageMemoryCacheCapacityInBytes
        }
    }
    
    public lazy var session: URLSession = URLSession(configuration: urlSessionConfiguration)
    
    public lazy var urlCache: URLCache = {
        return URLCache(
            memoryCapacity: 40.megabytesInBytes,
            diskCapacity: 250.megabytesInBytes,
            diskPath: "com.okcupid.imagedownloader"
        )
    }()
    
    public lazy var imageMemoryCache: NSCache<NSURL, CachableContainer<UIImage>> = {
        let imageCache = NSCache<NSURL, CachableContainer<UIImage>>()
        imageCache.totalCostLimit = imageMemoryCacheCapacityInBytes
        return imageCache
    }()
    
    public lazy var urlSessionConfiguration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = urlCache
        return configuration
    }()
    
    // MARK: - Internal Properties
    
    let synchronizationQueue: DispatchQueue = {
        let name = String(format: "com.okcupid.imagedownloader.synchronizationqueue-%08x%08x", arc4random(), arc4random())
        return .init(label: name, qos: .userInteractive)
    }()
    
    let imageProcessingQueue: DispatchQueue = {
        let name = String(format: "com.okcupid.imagedownloader.imageProcessingQueue-%08x%08x", arc4random(), arc4random())
        return .init(label: name, qos: .userInteractive)
    }()
    
    lazy var currentLoaders = [URL: APIUrlLoader<ImageDownloaderRequest>]()
    lazy var currentCompletionHandlers = [URL: [ImageDownloaderReceipt: CompletionHandler]]()
    
    private let notificationCenter: NotificationCenter
    
    // MARK: - Lifecycle
    
    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        self.notificationCenter.addObserver(self, selector: #selector(didReceiveMemoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    // MARK: - Downloading
    
    public func download(url: URL, receiptHandler: ImageDownloaderReceiptHandling? = nil, completionHandler: @escaping CompletionHandler) {
        let receipt: ImageDownloaderReceipt = .init(id: UUID(), url: url)
        receiptHandler?.imageDownloaderReceipt = receipt
        
        guard !checkForImageInCacheAndCompleteIfNeeded(with: url, receipt: receipt, completionHandler: completionHandler) else {
            return
        }
        
        synchronizationQueue.sync {
            guard !checkForCurrentLoaderInProgressAndAppendCompletionIfNeeded(with: url, receipt: receipt, completionHandler: completionHandler) else {
                return
            }
            
            let request: ImageDownloaderRequest = .init(url: url)
            let loader: APIUrlLoader<ImageDownloaderRequest> = .init(apiRequest: request, urlSession: session)
            
            currentCompletionHandlers[url] = [receipt: completionHandler]
            currentLoaders[url] = loader
            
            loader.load { [weak self] image, error in
                self?.processSuccessfulResponse(url: url, image: image, error: error)
            } 
        }
    }
    
    // MARK: - Cancelling
    
    public func cancel(url: URL, receipt: ImageDownloaderReceipt? = nil) {
        synchronizationQueue.sync {
            complete(url: url, receipt: receipt, dataResponse: .failure(ImageDownloaderError.cancelled))
        }
    }
    
    // MARK: - Notifications
    
    @objc func didReceiveMemoryWarning() {
        imageMemoryCache.removeAllObjects()
    }
    
    // MARK: - Internal Helpers
    
    func activeCompletionHandlers(for url: URL) -> Int {
        let completionHandlers: [CompletionHandler] = currentCompletionHandlers[url]?.keys.compactMap { currentCompletionHandlers[url]?[$0] } ?? []
        return completionHandlers.count
    }
    
    func checkForCurrentLoaderInProgressAndAppendCompletionIfNeeded(with url: URL, receipt: ImageDownloaderReceipt, completionHandler: @escaping CompletionHandler) -> Bool {
        if currentLoaders[url] != nil {
            if var receiptDictionary: [ImageDownloaderReceipt: CompletionHandler] = currentCompletionHandlers[url] {
                receiptDictionary[receipt] = completionHandler
                currentCompletionHandlers[url] = receiptDictionary
                
            } else {
                let receiptDictionary: [ImageDownloaderReceipt: CompletionHandler] = [receipt: completionHandler]
                currentCompletionHandlers[url] = receiptDictionary
            }
            
            return true
        }
        
        return false
    }
    
    func checkForImageInCacheAndCompleteIfNeeded(with url: URL, receipt: ImageDownloaderReceipt, completionHandler: @escaping CompletionHandler) -> Bool {
        if let imageCachableContainer: CachableContainer<UIImage> = imageMemoryCache.object(forKey: url as NSURL) {
            completionHandler(.success(imageCachableContainer.object), receipt)
            
            return true
        }
        
        return false
    }
    
    func complete(url: URL, receipt: ImageDownloaderReceipt?, dataResponse: Result<UIImage, ImageDownloaderError>) {
        let completionHandlersAndReceipts: [(completionHandler: CompletionHandler, imageDownloadReceipt: ImageDownloaderReceipt)]
        
        var shouldCancelLoader: Bool = false
        
        if let receipt = receipt, let completionHandlerForReceipt = currentCompletionHandlers[url]?[receipt] {
            completionHandlersAndReceipts = [(completionHandlerForReceipt, receipt)]
            currentCompletionHandlers[url]?[receipt] = nil
            shouldCancelLoader = currentCompletionHandlers[url]?.keys.count == 0
            
        } else if let completionHandlersAndReceiptsForUrl = currentCompletionHandlers[url] {
            completionHandlersAndReceipts = completionHandlersAndReceiptsForUrl.compactMap { ($1, $0) }
            currentCompletionHandlers[url] = nil
            shouldCancelLoader = true
            
        } else {
            completionHandlersAndReceipts = []
            shouldCancelLoader = true
        }
        
        if shouldCancelLoader {
            currentLoaders[url]?.cancel()
            currentLoaders[url] = nil
        }
        
        DispatchQueue.main.async {
            completionHandlersAndReceipts.forEach { $0.completionHandler(dataResponse, $0.imageDownloadReceipt) }
        }
    }
    
    func processSuccessfulResponse(url: URL, image: UIImage?, error: ImageDownloaderError?) {
        imageProcessingQueue.async {
            let dataResponse: Result<UIImage, ImageDownloaderError>
            
            defer {
                self.synchronizationQueue.sync {
                    self.complete(url: url, receipt: nil, dataResponse: dataResponse)
                }
            }
            
            if let error = error {
                dataResponse = .failure(error)
                return
            }
            
            guard let image = image else {
                dataResponse = .failure(ImageDownloaderError.dataInvalid)
                return
            }
            
            let imageCost: Int = image.pngData()?.count ?? 0
            self.imageMemoryCache.setObject(CachableContainer(object: image), forKey: url as NSURL, cost: imageCost)
            
            dataResponse = .success(image)
        }
    }
    
}
