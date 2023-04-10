//
//  LoginsTableViewCell.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/21/23.
//

import UIKit

class LoginsTableViewCell: UITableViewCell {

    @IBOutlet weak var loginTime: UILabel!
    @IBOutlet weak var loginSuccess: UILabel!
    @IBOutlet weak var loginImageView: UIImageView!
    
    var login: Login! {
        didSet {
            let d = Date(timeIntervalSince1970: login.time)
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = TimeZone.current
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .long
            loginTime.text = dateFormatter.string(from: d)
            loginSuccess.text = login.result ? "Successful Login" : "Blocked Entry"
            loginSuccess.textColor = login.result ? .green : .red
            if let fileName = login.fileName, let fileUrl = getFileURL(for: fileName) {
                loginImageView.isHidden = false
                do {
                    loginImageView.image = UIImage(data: try Data(contentsOf: fileUrl))
                } catch {
                    print("Could not set image")
                    loginImageView.isHidden = true
                }
            } else {
                loginImageView.isHidden = true
                loginImageView.image = nil
            }
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        loginImageView.layer.cornerRadius = 10
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
