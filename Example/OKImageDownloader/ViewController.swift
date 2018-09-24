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
        
        imageView.downloadImage(with: URL(string: "https://www.popsci.com/sites/popsci.com/files/styles/655_1x_/public/images/2017/10/terrier-puppy.jpg?itok=Ppdi06hH&fc=50,50")!, completionHandler: nil)
    }

}
