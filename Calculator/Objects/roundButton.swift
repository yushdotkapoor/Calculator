//
//  roundButton.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 1/19/21.
//

import UIKit

class RoundButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        setupButton()
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder: aDecoder)
        setupButton()
    }
    
    func setupButton() {
        layer.cornerRadius = frame.size.height/2
    }
}
