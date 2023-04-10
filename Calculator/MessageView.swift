//
//  MessageView.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/19/23.
//

import Foundation
import UIKit
import Firebase
import SwiftyJSON

class MessageView: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        UserDefaults.standard.addObserver(self, forKeyPath: "threads", options: [.new], context: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "threads")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "threads" {
            tableView.reloadData()
        }
    }
    
    @IBAction func newThread(_ sender: Any) {
        let alerter = UIAlertController(title: "Create New Message", message: "Enter the 6 digit code of your recipient", preferredStyle: .alert)
        
        alerter.addTextField { (textField) in
            textField.text = ""
            textField.keyboardType = .numberPad
        }
        
        alerter.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alerter.addAction(UIAlertAction(title: "Create", style: .default, handler: { [weak alerter] (_) in
            let textField = alerter?.textFields![0]
            let num = textField!.text! as String
            self.createNewThread(recipient: num)
        }))
        
        if !CheckInternet.Connection() {
            self.alert(title: "Uh-Oh", message: "Please check your internet connection! You will not be able to send or recieve messages without internet.", actionTitle: "Okay") {
                self.present(alerter, animated: true, completion: nil)
            }
        } else {
            self.present(alerter, animated: true, completion: nil)
        }
    }
    
    
    func createNewThread(recipient: String) {
        if let threads = UserDefaults.standard.dictionary(forKey: "threads"), let threadUsers = threads["uids"] as? [String: String], Array(threadUsers.keys).contains(recipient) {
            self.alert(title: "Error", message: "This message thread already exists.", actionTitle: "Okay")
        } else if recipient == myKey {
            self.alert(title: "Error", message: "You have entered your own code. You cannot message yourself.", actionTitle: "Okay")
        } else if !allKeys.contains(recipient) {
            self.alert(title: "Error", message: "No such user code exists, check the code again.", actionTitle: "Okay")
        } else {
            let threadID = "\(Date().betterDate()) - \(UUID().uuidString)"
            let recEn = 😂(🥮: recipient, 🥛: "987654", 🎂: "123456", 🍟: Date(timeIntervalSince1970: 0), 🫐: "nick \(threadID)")
            let myEn = 😂(🥮: myKey, 🥛: "987654", 🎂: "123456", 🍟: Date(timeIntervalSince1970: 0), 🫐: "nick \(threadID)")
            var array: [String: Any] = ["uids":[myKey:false, recipient:false], "nick": recEn]
            ref.child("Users").child(myKey).child("threads").child(threadID).setValue(array)
            array["nick"] = myEn
            ref.child("Users").child(recipient).child("threads").child(threadID).setValue(array)
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UserDefaults.standard.dictionary(forKey: "threads")?.count ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MessagesListCell
        let threadsCache = UserDefaults.standard.dictionary(forKey: "threads") ?? [:]
        let threads = threadsCache.sorted(by: { $0.key < $1.key })
        let threadID = threads[indexPath.row].key
        let threadData = threadsCache[threadID] as? NSDictionary ?? [:]
        let userIDs = threadData["uids"] as? [String: Bool] ?? [:]
        var name = userIDs.first(where: { $0.key != myKey })!.key
        if let nicknames = UserDefaults.standard.dictionary(forKey: "aliases") as? [String: String], let alias = nicknames[name] {
            name = alias
        }
        
        cell.label.text = name
        cell.img.image = userIDs[myKey]! ? UIImage(systemName: "circle.fill") : nil
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let threadsCache = UserDefaults.standard.dictionary(forKey: "threads") ?? [:]
        let threads = threadsCache.sorted(by: { $0.key < $1.key })
        let threadID = threads[indexPath.row].key
        let threadData = threadsCache[threadID] as? NSDictionary ?? [:]
        let userIDs = threadData["uids"] as? [String: Bool] ?? [:]
        let selectedUser = userIDs.first(where: { $0.key != myKey })!.key
        
        let vc = ChatViewController()
        vc.threadAggregator = threadAggregators.first(where: { $0.threadUsers.me.senderId == myKey && $0.threadUsers.them.senderId == selectedUser })
        
        navigationController?.pushViewController(vc, animated: true)
    }
}
