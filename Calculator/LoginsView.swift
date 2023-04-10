//
//  LoginsView.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/21/23.
//

import Foundation
import UIKit

class LoginsView: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var logins: [Login] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Logins"
        
        tableView.delegate = self
        tableView.dataSource = self
        
        if let loginsCache = UserDefaults.standard.data(forKey: "logins") {
            do {
                logins = try PropertyListDecoder().decode([Login].self, from: loginsCache)
            } catch {
                print("Error in retrieving logins")
            }
        }
        logins.sort(by: { $0.time > $1.time })
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logins.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? LoginsTableViewCell {
            cell.login = logins[indexPath.row]
            
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let cell = tableView.cellForRow(at: indexPath) as? LoginsTableViewCell, let _ = cell.loginImageView.image, let fileName = cell.login.fileName, let fileUrl = getFileURL(for: fileName) {
            
            let vc = PhotoViewerViewController(with: fileUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}
