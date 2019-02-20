//
//  CollectionViewCell.swift
//  VirtualTourist
//
//  Created by Ashish Nautiyal on 2/16/19.
//  Copyright © 2019 Ashish  Nautiyal. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    // Outlets
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    override func prepareForReuse() {
        super.prepareForReuse()
        img.image = nil
        activityIndicator.stopAnimating()
    }
    
}
