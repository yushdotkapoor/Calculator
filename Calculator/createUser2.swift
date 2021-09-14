//
//  createUser2.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 1/19/21.
//

import UIKit
import Firebase


class createUser2: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    var justStarted = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        justStarted = true
        updateKeys()
        tabBarIndex = 0
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
        let pass = data.string(forKey: "tempPassword")
        if updatePassKey {
            if label.text == pass {
                data.setValue(pass, forKey: "Password")
                updatePassKey = false
                alert(title: "Success", message: "Your password has been updated", actionTitle: "Okay", actions: {
                    self.performSegue(withIdentifier: "createUser2ToMessageView", sender: nil)
                    })
            }
            else {
                alert(title: "Error", message: "Passwords do not match, please try again", actionTitle: "Okay", actions: {
                    
                    self.performSegue(withIdentifier: "createUser2ToCreateUser", sender: nil)
                    })
            }
        }
        else {
            rList.removeAll()
            rListThread.removeAll()
            rListNotification.removeAll()
            
        let token = data.string(forKey: "token")
        
        if label.text == pass {
            data.setValue(pass, forKey: "Password")
            if !userExists() {
                data.setValue(true, forKey: "exists")
                let key = keyGenerator(keyArrays: allKeys)
                myKey = key
                data.setValue(key, forKey: "key")
                let array = ["recipients":["0": "N"], "messages":["0": ["type":"", "sender":"", "date":0, "data":"", "id":""]]] as [String : Any]
                let data = ["key": key, "threads":["0":array], "Notifcations":["token":"\(token ?? "")", "sender":"N", "body":"N"], "Q": "Y"] as [String : Any]
                ref.child("users/\(key)").setValue(data)
                alert(title: "Success", message: "Your user has been created.", actionTitle: "Okay", actions: {
                    self.performSegue(withIdentifier: "createUser2ToMessageView", sender: nil)
                    })
            }
            else {
            alert(title: "Success", message: "Your password has been updated.", actionTitle: "Okay", actions: {
                self.performSegue(withIdentifier: "createUser2ToMessageView", sender: nil)
                })
            }
        }
        else {
            alert(title: "Error", message: "Passwords do not match, please try again", actionTitle: "Okay", actions: {
                
                self.performSegue(withIdentifier: "createUser2ToCreateUser", sender: nil)
                })
        }
        }
    }
    
    @IBAction func clear(_ sender: Any) {
        label.text = "0"
        justStarted = true
    }
    
    @IBAction func back(_ sender: Any) {
        self.performSegue(withIdentifier: "createUser2ToCreateUser", sender: nil)
    }
    
}

func keyGenerator(keyArrays:Array<String>) -> String {
    var string = ""
    var i = 0
    while i < 4 {
    let random = Int.random(in: 0..<10)
        string.append("\(random)")
        i += 1
    }
    if keyArrays.contains("string") {
        return keyGenerator(keyArrays: keyArrays)
    }
    return string
}
