//
//  updatePassword.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 1/23/21.
//

import UIKit

class updatePassword: UIViewController {

    @IBOutlet weak var label: UILabel!
    var justStarted = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        justStarted = true
        let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return true
    }
    func passkeyCheck() {
        let pass = data.string(forKey: "Password")
        if label.text == pass {
            self.performSegue(withIdentifier: "updatePassword1", sender: nil)
        }
    }
    
    func zeroCheck() {
        if justStarted {
            label.text = ""
            justStarted = false
        }
    }
    
    @IBAction func zero(_ sender: Any) {
        zeroCheck()
        label.text?.append("0")
    }
    
    @IBAction func one(_ sender: Any) {
        zeroCheck()
        label.text?.append("1")
    }
    
    @IBAction func two(_ sender: Any) {
        zeroCheck()
        label.text?.append("2")
    }
    
    @IBAction func three(_ sender: Any) {
        zeroCheck()
        label.text?.append("3")
    }
    
    @IBAction func four(_ sender: Any) {
        zeroCheck()
        label.text?.append("4")
    }
    
    @IBAction func five(_ sender: Any) {
        zeroCheck()
        label.text?.append("5")
    }
    
    @IBAction func six(_ sender: Any) {
        zeroCheck()
        label.text?.append("6")
    }
    
    @IBAction func seven(_ sender: Any) {
        zeroCheck()
        label.text?.append("7")
    }
    
    @IBAction func eight(_ sender: Any) {
        zeroCheck()
        label.text?.append("8")
    }
    
    @IBAction func nine(_ sender: Any) {
        zeroCheck()
        label.text?.append("9")
    }
    
    @IBAction func point(_ sender: Any) {
        label.text?.append(".")
    }
    
    @IBAction func enter(_ sender: Any) {
      passkeyCheck()
    }
    
    @IBAction func clear(_ sender: Any) {
        label.text = "0"
        justStarted = true
    }

}
