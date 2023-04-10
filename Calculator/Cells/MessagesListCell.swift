//
//  MessagesListCell.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 1/22/21.
//

import UIKit

class MessagesListCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var img: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
