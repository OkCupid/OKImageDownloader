//
//  ViewController.swift
//  OKImageDownloader-Example
//
//  Created by Jordan Guggenheim on 9/21/20.
//

import UIKit
import OKImageDownloader

final class ViewController: UIViewController {

    @IBOutlet private weak var imageView: UIImageView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        imageView.downloadImage(with: URL(string: "https://www.gstatic.com/webp/gallery/4.webp")!) { (response, receipt) in
            switch response {
            case .success(let image):
                self.imageView.image = image
                
            case .failure(let error):
                print(error)
            }
        }
    }

}

