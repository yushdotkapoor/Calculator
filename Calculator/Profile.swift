//
//  Profile.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 1/23/21.
//

import UIKit

class Profile: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var code: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    let settingsData = [("Notifications", "notificationSettings"), ("Authentication & Security", "authenticationSettings")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        code.text = "Your Code: \(myKey)"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
        tabBarController?.tabBar.isHidden = false
    }
    
    @IBAction func viewLogins(_ sender: Any) {
        if let vc = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(identifier: "loginsView") as? LoginsView {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func goToWelcomePage(_ sender: Any) {
        if let vc = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(identifier: "welcome") as? WelcomeView {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:"cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = settingsData[indexPath.row].0
                
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
                
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var newVc: UIViewController?
        if let vc = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(identifier: settingsData[indexPath.row].1) as? NotificationSettings {
            newVc = vc
        } else if let vc = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(identifier: settingsData[indexPath.row].1) as? AuthenticationSettings {
            newVc = vc
        }
        
        if let newVc = newVc {
            newVc.title = settingsData[indexPath.row].0
            navigationController?.pushViewController(newVc, animated: true)
        }
    }
    
    
}
