//
//  ViewController.swift
//  OKImageDownloader
//
//  Created by Jordan Guggenheim on 09/19/2018.
//  Copyright (c) 2018 OkCupid. All rights reserved.
//

import UIKit
import OKImageDownloader

final class ViewController: UIViewController {
    
    @IBOutlet private weak var imageView: UIImageView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        imageView.downloadImage(with: URL(string: "https://cdn.okccdn.com/media/img/hub/mediakit/okcupid_darkbg_2019.png")!, completionHandler: nil)
    }

}
