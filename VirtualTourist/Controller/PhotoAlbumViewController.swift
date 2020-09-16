//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Márcio Oliveira on 9/16/20.
//  Copyright © 2020 Márcio Oliveira. All rights reserved.
//

import UIKit

class PhotoAlbumViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    var test: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        label.text = test
    }
    

}
