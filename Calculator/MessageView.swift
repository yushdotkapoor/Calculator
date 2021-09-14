//
//  MessageView.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 1/19/21.
//

import UIKit
import Firebase
import AudioToolbox

var myKey = ""

var selectedThread = ""
var selectedUser = ""

struct UserObject {
    var id: String?
    var alias: String?
}

class MessageView: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var myTable: UITableView!
    
    lazy var refresher: UIRefreshControl = {
    let refreshControl = UIRefreshControl()
    refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(initialize), for: .valueChanged)
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myKey = data.string(forKey: "key")! as String
        tabBarIndex = 0
        selectedThread = ""
        
        if (rList.count == 0) {
            initialize()
        }
        notificationListener()
        
        myTable.register(UITableViewCell.self, forCellReuseIdentifier: "shell")
        myTable.delegate = self
        myTable.dataSource = self
        myTable.estimatedRowHeight = 40
        
        myTable.refreshControl = refresher
        
        setCount()
        
        if !CheckInternet.Connection() {
            self.alert(title: "Uh-Oh", message: "Please check your internet connection! You will not be able to send or recieve messages without internet.", actionTitle: "Okay")
        }
        
    }
    
    func notificationListener() {
        ref.child("users/\(myKey)/threads").observe(.childChanged, with: { (snapshot) in
            let value = snapshot.value as! NSDictionary
            let threadID = snapshot.key
            let read = value["recipients"] as? [String:String] ?? [:]
                
            for n in read {
                let ke = n.key
                let val = n.value
                
                if ke == myKey && threadID != "0"  {
                    let index = rListThread.firstIndex(of: "\(threadID)")!
                    
                    if isView(selfView: self, checkView: MessageView.self) {
                        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                    }
                    
                    rListNotification[index] = "\(val)"
                    
                    if !rListNotification.contains("Y") {
                        UIApplication.shared.applicationIconBadgeNumber = 0
                    }
                    else {
                        UIApplication.shared.applicationIconBadgeNumber = 1
                    }
                        
                    self.setCount()
                    self.myTable.reloadData()
                }
            }
        })
    }
    
    @objc func initialize() {
        rList.removeAll()
        rListThread.removeAll()
        rListNotification.removeAll()
        let nickArray = data.object(forKey: "Aliases") as? [String:String] ?? [:]
        ref.child("users/\(myKey)/threads").observe(.childAdded, with: { (snapshot) in
            let value = snapshot.value as! NSDictionary
            let threadID = snapshot.key
            
            let read = value["recipients"] as? [String:String] ?? [:]
            
            for (i, n) in read.enumerated() {
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
                    self.setCount()
                    self.myTable.reloadData()
                }
                if i + 1 == read.count {
                    self.refresher.endRefreshing()
                }
            }
        })
    }
    
    func setCount() {
        var count = 0
        var count2 = 0
        
        for j in rListNotification {
            if j == "Y" {
                count += 1
            }
            count2 += 1
            
            if count2 == rListNotification.count {
                if count == 0 {
                    self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Messages", style: .plain, target: self, action: nil)
                }
                else {
                    self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "\(count)", style: .plain, target: self, action: nil)
                }
            }
        }
        
    }
    
    @IBAction func newThread(_ sender: Any) {
        updateKeys()
        if !CheckInternet.Connection() {
            self.alert(title: "Uh-Oh", message: "Please check your internet connection! You will not be able to send or recieve messages without internet.", actionTitle: "Okay")
            return
        }
        let alerter = UIAlertController(title: "Create New Message", message: "Enter the 4 digit code of your recipient", preferredStyle: .alert)

        alerter.addTextField { (textField) in
            textField.text = ""
            textField.keyboardType = .numberPad
        }
        
        alerter.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alerter.addAction(UIAlertAction(title: "Create", style: .default, handler: { [weak alerter] (_) in
            let textField = alerter?.textFields![0]
            let num = textField!.text! as String
            self.newThreadCompletion(num:num)
        }))
        self.present(alerter, animated: true, completion: nil)
    }
    
    func getIDs() -> [String] {
        var a:[String] = []
        for i in rList {
            a.append(i.id!)
        }
        return a
    }
    
    func newThreadCompletion(num:String) {
        if getIDs().contains(num) {
            self.alert(title: "Error", message: "This message thread already exists.", actionTitle: "Okay")
        }
        else if num == myKey {
            self.alert(title: "Error", message: "You have entered your own code. You cannot message yourself.", actionTitle: "Okay")
        }
        else if !allKeys.contains(num) {
                self.alert(title: "Error", message: "No such code exists with a user, check the code again.", actionTitle: "Okay")
            }
        else {
            
            let id = "\(Date()) - \(UUID().uuidString)"
        
            let array = ["recipients":[num: "D", myKey: "N"], "messages":["0": ["type":"", "sender":"", "date":0, "data":"", "id":""]]] as [String : Any]
                
            ref.child("users/\(myKey)/threads/\(id)").setValue(array)
            ref.child("users/\(num)/threads/\(id)").setValue(array)
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! MessagesListCell
        
        let rListUser = rList[indexPath.row]
        var name = rListUser.id
        let alias = rListUser.alias
        if alias != "" {
            name = alias
        }
        
        
        cell.label.text = name
        
        if rListNotification[indexPath.row] == "Y" {
            cell.img.image = UIImage(systemName: "circle.fill")
        }
        else {
            cell.img.image = nil
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if !CheckInternet.Connection() {
            self.alert(title: "Uh-Oh", message: "Please check your internet connection! You will not be able to send or recieve messages without internet.", actionTitle: "Okay")
          return
        }
        let rListUser = rList[indexPath.row]
        var name = rListUser.id
        let alias = rListUser.alias
        if alias != "" {
            name = alias
        }
        
        let vc = ChatViewController()
        vc.title = name
        selectedUser = rListUser.id ?? ""
        navigationController?.pushViewController(vc, animated: true)
        selectedThread = rListThread[indexPath.row]
    }
  
}


