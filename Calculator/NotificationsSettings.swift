//
//  NotificationsSettings.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/29/23.
//

import Foundation
import UIKit

class NotificationSettings: UIViewController {
    
    @IBOutlet weak var codeSwitch: UISwitch!
    @IBOutlet weak var bodySwitch: UISwitch!
    @IBOutlet weak var notificationPreviewView: UIView!
    @IBOutlet weak var notificationImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var messageTextField: UITextField!
    
    let exampleTitle = "000000"
    let exampleBody = "This is an example message"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref.child("Users").child(myKey).observeSingleEvent(of: .value, with: { [self] (snapshot) in
            if let val = snapshot.value as? NSDictionary {
                let nob = val["notifyWithBody"] as! String
                let nos = val["notifyWithSender"] as! String
                codeSwitch.setOn(nob == " ", animated: false)
                bodySwitch.setOn(nos == " ", animated: false)
                titleTextField.isEnabled = !codeSwitch.isOn
                messageTextField.isEnabled = !bodySwitch.isOn
                updateNotificationPreview()
            }
        })
        
        notificationPreviewView.layer.cornerRadius = 20
        notificationImage.layer.cornerRadius = 10
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(notificationPreviewViewTapped))
        notificationPreviewView.addGestureRecognizer(tapGesture)
        
        let viewGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        view.addGestureRecognizer(viewGesture)
        
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(viewTapped))
        toolBar.setItems([flexibleSpace, doneButton], animated: false)
        
        for field in [titleTextField!, messageTextField!] {
            field.inputAccessoryView = toolBar
            field.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let dictVal = notificationStyleDict.first(where: { $0.key == UIApplication.shared.alternateIconName ?? "Calculator" })!
        notificationImage.image = UIImage(named: dictVal.key)
        
        updateNotificationPreview()
    }
    
    func updateNotificationPreview() {
        let dictVal = notificationStyleDict.first(where: { $0.key == UIApplication.shared.alternateIconName ?? "Calculator" })!
        var defaultTitle = UserDefaults.standard.string(forKey: "notificationTitle") ?? dictVal.value["title"]
        var defaultBody = UserDefaults.standard.string(forKey: "notificationBody") ?? dictVal.value["body"]
        if defaultTitle == exampleTitle {
            defaultTitle = dictVal.value["title"]
        }
        if defaultBody == exampleBody {
            defaultBody = dictVal.value["body"]
        }
        
        titleTextField.text = codeSwitch.isOn ? exampleTitle : defaultTitle
        titleTextField.backgroundColor = codeSwitch.isOn ? UIColor.secondarySystemBackground: UIColor.secondaryLabel
        messageTextField.text = bodySwitch.isOn ? exampleBody : defaultBody
        messageTextField.backgroundColor = bodySwitch.isOn ? UIColor.secondarySystemBackground: UIColor.secondaryLabel
        textFieldDidChange()
        
        titleTextField.isEnabled = !codeSwitch.isOn
        messageTextField.isEnabled = !bodySwitch.isOn
    }
    
    @objc func notificationPreviewViewTapped(_ sender: UITapGestureRecognizer) {
        if let vc = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(identifier: "notificationStyleView") as? NotificationStyleView {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc func textFieldDidChange() {
        titleLabel.text = titleTextField.text
        bodyLabel.text = messageTextField.text
        UserDefaults.standard.setValue(titleLabel.text, forKey: "notificationTitle")
        UserDefaults.standard.setValue(bodyLabel.text, forKey: "notificationBody")
        ref.child("Users").child(myKey).child("notifyWithSender").setValue(codeSwitch.isOn ? " " : titleLabel.text)
        ref.child("Users").child(myKey).child("notifyWithBody").setValue(bodySwitch.isOn ? " " : bodyLabel.text)
    }
    
    @objc func viewTapped() {
        view.endEditing(true)
    }
    
    @IBAction func senderCode(_ sender: Any) {
        updateNotificationPreview()
        ref.child("Users").child(myKey).child("notifyWithSender").setValue(codeSwitch.isOn ? " " : titleLabel.text)
    }
    
    
    @IBAction func content(_ sender: Any) {
        updateNotificationPreview()
        ref.child("Users").child(myKey).child("notifyWithBody").setValue(bodySwitch.isOn ? " " : bodyLabel.text)
    }
    
    
    @IBAction func resetToDefault(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "notificationTitle")
        UserDefaults.standard.removeObject(forKey: "notificationBody")
        updateNotificationPreview()
    }
    
}
