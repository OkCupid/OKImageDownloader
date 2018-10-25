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
    
    public typealias CompletionHandler = (_ dataResponse: DataResponse<UIImage>, _ downloadReceipt: ImageDownloaderReceipt) -> Void
    public static let shared = ImageDownloader()
    
    public var imageCacheCapacityInBytes: Int = 40.megabytesInBytes {
        didSet {
            imageCache.totalCostLimit = imageCacheCapacityInBytes
        }
    }
    
    public lazy var urlCache: URLCache = {
        return URLCache(
            memoryCapacity: 40.megabytesInBytes,
            diskCapacity: 250.megabytesInBytes,
            diskPath: "com.okcupid.imagedownloader"
        )
    }()
    
    public lazy var urlSessionConfiguration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = urlCache
        return configuration
    }()
    
    // MARK: - Internal Properties
    
    lazy var session: URLSession = URLSession(configuration: urlSessionConfiguration)
    
    lazy var imageCache: NSCache<NSURL, CachableContainer<UIImage>> = {
        let imageCache = NSCache<NSURL, CachableContainer<UIImage>>()
        imageCache.totalCostLimit = imageCacheCapacityInBytes
        return imageCache
    }()
    
    let synchronizationQueue: DispatchQueue = {
        let name = String(format: "com.okcupid.imagedownloader.synchronizationqueue-%08x%08x", arc4random(), arc4random())
        return DispatchQueue(label: name)
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
        let receipt = ImageDownloaderReceipt(id: UUID(), url: url)
        receiptHandler?.imageDownloaderReceipt = receipt
        
        synchronizationQueue.sync {
            guard !checkForImageInCacheAndCompleteIfNeeded(with: url, receipt: receipt, completionHandler: completionHandler) else {
                return
            }
            
            guard !checkForCurrentLoaderInProgressAndAppendCompletionIfNeeded(with: url, receipt: receipt, completionHandler: completionHandler) else {
                return
            }
            
            let request = ImageDownloaderRequest(url: url)
            let loader = APIUrlLoader<ImageDownloaderRequest>(apiRequest: request, urlSession: session)
            
            currentCompletionHandlers[url] = [receipt: completionHandler]
            currentLoaders[url] = loader
            
            loader.load { image, error in
                self.processSuccessfulResponse(url: url, image: image, error: error)
            } 
        }
    }
    
    // MARK: - Cancelling
    
    public func cancel(url: URL, receipt: ImageDownloaderReceipt? = nil) {
        synchronizationQueue.sync {
            
            if activeCompletionHandlers(for: url) == 1 {
                currentLoaders[url]?.cancel()
            }
            
            complete(url: url, receipt: receipt, dataResponse: .failure(ImageDownloaderError.cancelled))
        }
    }
    
    // MARK: - Notifications
    
    @objc func didReceiveMemoryWarning() {
        imageCache.removeAllObjects()
    }
    
    // MARK: - Internal Helpers
    
    func activeCompletionHandlers(for url: URL) -> Int {
        let completionHandlers = currentCompletionHandlers[url]?.keys.compactMap { currentCompletionHandlers[url]?[$0] } ?? []
        return completionHandlers.count
    }
    
    func checkForCurrentLoaderInProgressAndAppendCompletionIfNeeded(with url: URL, receipt: ImageDownloaderReceipt, completionHandler: @escaping CompletionHandler) -> Bool {
        if currentLoaders[url] != nil {
            if var receiptDictionary = currentCompletionHandlers[url] {
                receiptDictionary[receipt] = completionHandler
                currentCompletionHandlers[url] = receiptDictionary
                
            } else {
                let receiptDictionary = [receipt: completionHandler]
                currentCompletionHandlers[url] = receiptDictionary
            }
            
            return true
        }
        
        return false
    }
    
    func checkForImageInCacheAndCompleteIfNeeded(with url: URL, receipt: ImageDownloaderReceipt, completionHandler: @escaping CompletionHandler) -> Bool {
        if let imageCachableContainer = imageCache.object(forKey: url as NSURL) {
            
            DispatchQueue.main.async {
                completionHandler(.success(imageCachableContainer.object), receipt)
            }
            
            return true
        }
        
        return false
    }
    
    func complete(url: URL, receipt: ImageDownloaderReceipt?, dataResponse: DataResponse<UIImage>) {
        let completionHandlersAndReceipts: [(completionHandler: CompletionHandler, imageDownloadReceipt: ImageDownloaderReceipt)]
        
        if let receipt = receipt, let completionHandlerForReceipt = currentCompletionHandlers[url]?[receipt] {
            completionHandlersAndReceipts = [(completionHandlerForReceipt, receipt)]
            currentCompletionHandlers[url]?[receipt] = nil
            
        } else if let completionHandlersAndReceiptsForUrl = currentCompletionHandlers[url] {
            completionHandlersAndReceipts = completionHandlersAndReceiptsForUrl.compactMap { ($1, $0) }
            currentCompletionHandlers[url] = nil
            
        } else {
            completionHandlersAndReceipts = []
        }
        
        if activeCompletionHandlers(for: url) == 0 {
            currentLoaders[url] = nil
        }
        
        DispatchQueue.main.async {
            completionHandlersAndReceipts.forEach { $0.completionHandler(dataResponse, $0.imageDownloadReceipt) }
        }
    }
    
    func processSuccessfulResponse(url: URL, image: UIImage?, error: Error?) {
        DispatchQueue.global(qos: .background).async {
            let dataResponse: DataResponse<UIImage>
            
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
            
            image.inflate()
            
            let imageCost = image.jpegData(compressionQuality: 1)?.count ?? 0
            self.imageCache.setObject(CachableContainer(object: image), forKey: url as NSURL, cost: imageCost)
            
            dataResponse = .success(image)
        }
    }
    
}
