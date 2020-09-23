//
//  ViewController.swift
//  Example
//
//  Created by Jordan Guggenheim on 9/22/20.
//

import UIKit
import OKImageDownloader

final class ViewController: UIViewController {
    
    @IBOutlet private weak var imageView: UIImageView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        imageView.ok.downloadImage(with: URL(string: "https://www.gstatic.com/webp/gallery/4.webp")!)
    }
}

