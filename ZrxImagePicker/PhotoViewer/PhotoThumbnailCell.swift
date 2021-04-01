//
//  PhotoThumbnailCell.swift
//  PhotoPreviewer
//
//  Created by Swami on 10/02/21.
//  Copyright © 2021 ZoomRx. All rights reserved.
//

import UIKit

class PhotoThumbnailCell: UICollectionViewCell {

    @IBOutlet weak var thumbnailImage: UIImageView!
    static var bundle: Bundle {
        return Bundle(for: PhotoThumbnailCell.self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
