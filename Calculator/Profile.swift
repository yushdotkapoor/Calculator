//
//  Profile.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 1/23/21.
//

import UIKit

class Profile: UIViewController {
    
    @IBOutlet weak var code: UILabel!
    @IBOutlet weak var codeSwitch: UISwitch!
    @IBOutlet weak var bodySwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarIndex = 1
        code.text = "Your Code: \(myKey)"
        
        ref.child("users/\(myKey)/Notifcations/sender").observeSingleEvent(of: .value, with: { (snapshot) in
          
            let val = snapshot.value as? String ?? ""
            
            if val == "N"{
                self.codeSwitch.setOn(false, animated: false)
            }
            else {
                self.codeSwitch.setOn(true, animated: false)
            }
            
        })
        
        ref.child("users/\(myKey)/Notifcations/body").observeSingleEvent(of: .value, with: { (snapshot) in
          
            let val = snapshot.value as? String ?? ""
            
            if val == "N"{
                self.bodySwitch.setOn(false, animated: false)
            }
            else {
                self.bodySwitch.setOn(true, animated: false)
            }
        })
        
        
    }
    
    @IBAction func changePass(_ sender: Any) {
        updatePassKey = true
        self.performSegue(withIdentifier: "updatePassword", sender: nil)
    }
    
    @IBAction func senderCode(_ sender: Any) {
        if codeSwitch.isOn {
            ref.child("users/\(myKey)/Notifcations/sender").setValue("Y")
        }
        else {
            ref.child("users/\(myKey)/Notifcations/sender").setValue("N")
        }
    }
    
    @IBAction func content(_ sender: Any) {
        if bodySwitch.isOn {
            ref.child("users/\(myKey)/Notifcations/body").setValue("Y")
        }
        else {
            ref.child("users/\(myKey)/Notifcations/body").setValue("N")
        }
    }
    
    
    
}
