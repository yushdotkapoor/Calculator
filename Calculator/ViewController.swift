//
//  ViewController.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 1/19/21.
//

import UIKit
import Firebase

let ref = Database.database().reference()

let data = UserDefaults.standard

var allKeys:[String] = []

var updatePassKey = false

var tabBarIndex = 0

//user codes to display in tableView
var rList:[UserObject] = []
//thread IDs for each tableView cell
var rListThread:[String] = []
//whether or not a new notification is available
var rListNotification:[String] = []

class ViewController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    
    var justStarted = true
    var keepTrack = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //data.removeObject(forKey: "exists")
        justStarted = true
        keepTrack = ""
        label.text = "0"
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        initialize()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !userExists() {
            self.performSegue(withIdentifier: "createUser", sender: nil)
            data.setValue("", forKey: "key")
        }
    }
    
    func initialize() {
        rList.removeAll()
        rListThread.removeAll()
        rListNotification.removeAll()
        let nickArray = data.object(forKey: "Aliases") as? [String:String] ?? [:]
        ref.child("users/\(myKey)/threads").observe(.childAdded, with: { (snapshot) in
            let value = snapshot.value as! NSDictionary
            let threadID = snapshot.key
            
            let read = value["recipients"] as? [String:String] ?? [:]
            
            for n in read {
                let ke = n.key
                let val = n.value
                if threadID != "0" {
                    if ke == myKey && !rListThread.contains(threadID)  {
                        rListThread.insert(threadID, at: 0)
                        rListNotification.insert("\(val)", at: 0)
                    }
                    else {
                        let nick = nickArray[ke] ?? ""
                        let u = UserObject(id: ke, alias: nick)
                        rList.insert(u, at: 0)
                    }
                }
            }
        })
    }
    
    func passkeyCheck() {
        let pass = data.string(forKey: "Password")
        if keepTrack == pass {
            self.performSegue(withIdentifier: "PasswordEntryToMessageView", sender: nil)
        }
    }
    
    func zeroCheck() {
        if justStarted {
            label.text = ""
            justStarted = false
        }
        label.text?.append("\(rand())")
    }
    
    @IBAction func zero(_ sender: Any) {
        zeroCheck()
        keepTrack.append("0")
    }
    
    @IBAction func one(_ sender: Any) {
        zeroCheck()
        keepTrack.append("1")
    }
    
    @IBAction func two(_ sender: Any) {
        zeroCheck()
        keepTrack.append("2")
    }
    
    @IBAction func three(_ sender: Any) {
        zeroCheck()
        keepTrack.append("3")
    }
    
    @IBAction func four(_ sender: Any) {
        zeroCheck()
        keepTrack.append("4")
    }
    
    @IBAction func five(_ sender: Any) {
        zeroCheck()
        keepTrack.append("5")
    }
    
    @IBAction func six(_ sender: Any) {
        zeroCheck()
        keepTrack.append("6")
    }
    
    @IBAction func seven(_ sender: Any) {
        zeroCheck()
        keepTrack.append("7")
    }
    
    @IBAction func eight(_ sender: Any) {
        zeroCheck()
        keepTrack.append("8")
    }
    
    @IBAction func nine(_ sender: Any) {
        zeroCheck()
        keepTrack.append("9")
    }
    
    @IBAction func point(_ sender: Any) {
        keepTrack.append(".")
        label.text?.append(".")
    }
    
    @IBAction func enter(_ sender: Any) {
        passkeyCheck()
    }
    
    @IBAction func clear(_ sender: Any) {
        label.text = "0"
        keepTrack = ""
        justStarted = true
    }
    
    @IBAction func info(_ sender: Any) {
        alert(title: "Information", message: "Enter your password and click the equals sign to access the app. If you have forgotten your password, contact the Developer. Password spoofing is on.", actionTitle: "Okay")
    }
    
    func rand() -> Int {
        return Int.random(in: 0..<10)
    }
    
}

func userExists() -> Bool {
    return data.object(forKey: "exists") != nil
}

func updateKeys() {
    var keyArrays:[String] = []
    ref.child("users").queryOrdered(byChild: "Q").queryEqual(toValue: "Y").observe(.childAdded, with: { (snapshot) in
        
        if let value = snapshot.value as? NSDictionary {
            keyArrays.append(value["key"] as! String)
        }
        allKeys = keyArrays
    })
}



func isView(selfView: UIViewController, checkView: AnyClass) -> Bool {
    if let viewController = selfView.navigationController?.visibleViewController {
        if viewController.isKind(of: checkView.self) {
            return true
        }
        return false
    }
    return false
}



