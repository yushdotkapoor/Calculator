//
//  NotificationStyleView.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/21/23.
//

import Foundation
import UIKit

class NotificationStyleView: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelection = false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notificationStyleDict.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? NotificationStyleTableViewCell {
            let dataValue = notificationStyleDict[indexPath.row]
            cell.imgView.image = UIImage(named: dataValue.key)
            cell.title.text = dataValue.value["title"]
            cell.body.text = dataValue.value["body"]
            
            cell.accessoryType = dataValue.key == UIApplication.shared.alternateIconName ?? "Calculator" ? .checkmark : .none
            
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let dataValue = notificationStyleDict[indexPath.row]
        changeIcon(name: dataValue.key)
        UserDefaults.standard.removeObject(forKey: "notificationTitle")
        UserDefaults.standard.removeObject(forKey: "notificationBody")
        tableView.reloadData()
        ref.child("Users").child(myKey).observeSingleEvent(of: .value, with: { (snapshot) in
            if let val = snapshot.value as? NSDictionary {
                let nob = val["notifyWithBody"] as! String
                let nos = val["notifyWithSender"] as! String
                
                let dataBack = ["notifyWithBody": nob == " " ? " " : dataValue.value["body"], "notifyWithSender": nos == " " ? " " : dataValue.value["title"]]
                
                ref.child("Users").child(myKey).updateChildValues(dataBack as [AnyHashable : Any])
            }
        })
    }
}
