//
//  firstTime.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 1/19/21.
//

import UIKit

class firstTime: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
}
