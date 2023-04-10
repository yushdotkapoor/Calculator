//
//  Media.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/25/23.
//

import Foundation
import MessageKit
import UIKit

struct Media: MediaItem {
    var url: URL?
    var fileName: String?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    init(url: URL? = nil, fileName: String? = nil, image: UIImage? = nil) {
        self.url = url
        self.image = image
        self.placeholderImage = image != nil ? image! : UIImage(named: "please_wait")!
        self.fileName = fileName ?? ""
        self.size = CGSize(width: 250, height: 375)
    }
}
