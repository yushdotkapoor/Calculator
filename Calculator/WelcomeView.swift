//
//  WelcomeView.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/22/23.
//

import Foundation
import UIKit


class WelcomeView: UIViewController {
    
    @IBOutlet weak var githubLink: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        githubLink.layer.cornerRadius = 20
        githubLink.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(githubTapped))
        githubLink.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        tabBarController?.tabBar.isHidden = true
    }
    
    @objc func githubTapped(_ sender: UITapGestureRecognizer) {
        UIApplication.shared.open(URL(string: "https://github.com/yushdotkapoor/Calculator")!)
    }
    
    @IBAction func nextPressed(_ sender: Any) {
        if let vc = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(identifier: "permissions") as? PermissionsView {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
