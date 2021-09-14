//
//  createUser.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 1/19/21.
//

import UIKit
import Firebase

class createUser: UIViewController {
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var label: UILabel!
    var justStarted = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        justStarted = true
        UserDefaults.standard.setValue("\(Messaging.messaging().fcmToken ?? "")", forKey: "token")
        
        if updatePassKey {
            header.text = "Choose New Password"
        }
        
        let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return true
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
        let text = label.text
        
        if text?.count ?? 0 < 4 || text?.count ?? 0 > 10 {
            alert(title: "Error", message: "Password must be between 4 and 10 characters in length", actionTitle: "Okay")
        }
        else {
        
        data.setValue(label.text, forKey: "tempPassword")
            self.performSegue(withIdentifier: "createUserToCreateUser2", sender: nil)
        }
        
    }
    
    @IBAction func clear(_ sender: Any) {
        label.text = "0"
        justStarted = true
    }
    
    
    @IBAction func back(_ sender: Any) {
        if updatePassKey {
            self.performSegue(withIdentifier: "createUserToUpdatePassword", sender: nil)
        }
        else {
            self.performSegue(withIdentifier: "createUserToSecondTime", sender: nil)
        }
    }
    
    
    
}
