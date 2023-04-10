//
//  CustomInformationCard.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 8/9/21.
//

import UIKit

class CustomInformationCard: NSObject, UIScrollViewDelegate, UITextFieldDelegate {
    
    private let backgroundView:UIView = UIView()
    
    private let alertView: UIView = {
        let alert = UIView()
        alert.backgroundColor = .darkGray
        alert.clipsToBounds = true
        alert.layer.masksToBounds = true
        alert.layer.cornerRadius = 15
        return alert
    }()
    
    private let titleLabel:UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.text = "User Information"
        lbl.font = lbl.font.withSize(25)
        lbl.textAlignment = .center
        lbl.textColor = .white
        return lbl
    }()
    
    private let closeButton = UIButton()
    
    var controller: ChatViewController!
    
    var PermaCode:String?
    var PermaTextField:UITextField?
    var PermaKeyboardHeight:CGFloat?
    var PermaKeyMove:CGFloat?
    
    @objc func tapExit(touch: UITapGestureRecognizer) {
        let touchPoint = touch.location(in: backgroundView)
        let location:CGPoint = CGPoint(x: touchPoint.x, y: touchPoint.y)
        
        if !alertView.frame.contains(location) {
            cancel()
            dismissAlert()
        }
    }
    
    func cancel() {
        backgroundView.gestureRecognizers?.forEach(backgroundView.removeGestureRecognizer)
    }
    
    @objc func doneClicked() {
        let _ = textFieldShouldReturn(PermaTextField!)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let AVP = alertView.frame.origin.y
        let AVHT = alertView.frame.size.height
        let deviceHT = UIScreen.main.bounds.height
        
        let distanceFromBottom = deviceHT - AVP - AVHT + 100
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
            let deltaHt = self.PermaKeyboardHeight! - distanceFromBottom
            self.PermaKeyMove = deltaHt
            UIView.animate(withDuration: 0.25, animations: {
                self.alertView.transform = CGAffineTransform(translationX: 0, y: self.PermaKeyMove!)
            })
        })
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.25, animations: {
            self.alertView.transform = .identity
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let newNick = textField.text, validateText(str: newNick) {
            var nicknames = UserDefaults.standard.dictionary(forKey: "aliases") as? [String: String] ?? [:]
            nicknames[PermaCode!] = newNick
            UserDefaults.standard.setValue(nicknames, forKey: "aliases")
            
            controller.title = newNick
            
            if let relevantUsers = UserDefaults.standard.data(forKey: "relevantUsers") {
                do {
                    var usrs = try PropertyListDecoder().decode([User].self, from: relevantUsers)
                    var relNode = usrs.first(where: { $0.senderId == PermaCode! })!
                    usrs.removeAll(where: { $0.senderId == PermaCode! })
                    relNode.displayName = newNick
                    usrs.append(relNode)
                    UserDefaults.standard.setValue(try! PropertyListEncoder().encode(usrs), forKey: "relevantUsers")
                } catch {
                    print("Error in retrieving relevantUsers")
                }
            }
            
            let recEn = 😂(🥮: newNick, 🥛: "987654", 🎂: "123456", 🍟: Date(timeIntervalSince1970: 0), 🫐: "nick \(controller.threadAggregator.selectedThread!)")
            ref.child("Users").child(myKey).child("threads").child(controller.threadAggregator.selectedThread).child("nick").setValue(recEn)
            controller.view.endEditing(true)
            return true
        } else {
            return false
        }
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            PermaKeyboardHeight = keyboardHeight
            print("keyboard height set")
        }
    }
    
    func validateText(str:String) -> Bool {
        if str == "" {
            //alert
            let alertController = UIAlertController(title: "Error", message: "You cannot leave this field blank", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            controller.present(alertController, animated: true, completion: nil)
            return false
        }
        if str.count > 20 {
            let alertController = UIAlertController(title: "Error", message: "Valid Aliases should not exceed 20 characters in length", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            controller.present(alertController, animated: true, completion: nil)
        }
        return true
    }
    
    
    func showAlert(userCode: String, viewController: ChatViewController) {
        PermaCode = userCode
        let nickArray = UserDefaults.standard.object(forKey: "aliases") as? [String:String] ?? [:]
        let nickName = nickArray[userCode] ?? userCode
        
        controller = viewController
        
        guard let targetView = controller.view else {
            return
        }
        backgroundView.frame = targetView.frame
        targetView.addSubview(backgroundView)
        
        alertView.isUserInteractionEnabled = true
        
        var width = targetView.frame.size.width-80
        if width > 500 {
            width = 500
        }
        
        alertView.frame = CGRect(x: 0, y: 0, width: width, height: 100)
        alertView.isHidden = true
        alertView.alpha = 0.0
        
        
        let titleLabelHeight = heightForView(text: "User Information", font: UIFont(name: "Helvetica", size: 25.0)!, width: alertView.frame.size.width - 10)
        //create a title label
        titleLabel.frame = CGRect(x: 5, y: 5, width: alertView.frame.size.width - 10, height: titleLabelHeight)
        
        
        let codeHt = heightForView(text: "Code: \(userCode)", font: UIFont(name: "Helvetica", size: 16.0)!, width: alertView.frame.size.width - 20)
        let code = UILabel(frame: CGRect(x: 10, y: titleLabelHeight + 20, width: alertView.frame.size.width - 20, height: codeHt))
        code.numberOfLines = 0
        code.text = "Code: \(userCode)"
        code.font = code.font.withSize(16)
        code.textAlignment = .left
        code.textColor = .white
        
        
        let nickHeaderHt = heightForView(text: "Alias:", font: UIFont(name: "Helvetica", size: 16.0)!, width: 40)
        let nickHeader = UILabel(frame: CGRect(x: 10, y: codeHt + titleLabelHeight + 50, width: 40, height: nickHeaderHt))
        nickHeader.text = "Alias:"
        nickHeader.font = code.font.withSize(16)
        nickHeader.textAlignment = .left
        nickHeader.textColor = .white
        
        
        let nickHt = heightForView(text: nickName, font: UIFont(name: "Helvetica", size: 16.0)!, width: alertView.frame.size.width - 70)
        let nick = UITextField(frame: CGRect(x: 60, y: codeHt + titleLabelHeight + 50, width: alertView.frame.size.width - 70, height: nickHt + 14))
        nick.text = nickName
        nick.font = code.font.withSize(16)
        nick.textColor = .white
        nick.backgroundColor = .black
        nick.layer.cornerRadius = 10
        nick.layer.masksToBounds = true
        let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: nick.frame.size.height))
        nick.leftView = paddingView
        nick.leftViewMode = .always
        nick.delegate = self
        nick.autocorrectionType = .no
        nick.autocapitalizationType = .words
        
        
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.save, target: self, action: #selector(self.doneClicked))
        toolBar.setItems([flexibleSpace, doneButton], animated: false)
        nick.inputAccessoryView = toolBar
        
        let totalHt = nickHt + codeHt + titleLabelHeight + 50
        
        PermaTextField = nick
        
        //set up button
        closeButton.frame = CGRect(x: alertView.frame.size.width / 2 - 37.5, y: totalHt + 55, width: 75, height: 25)
        closeButton.setTitle("Close", for: .normal)
        closeButton.titleLabel?.minimumScaleFactor = 0.5
        closeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.addTarget(self, action: #selector(dismissAlert), for: .touchUpInside)
        
        
        //resize alertView
        alertView.frame = CGRect(x: 0, y: 0, width: width, height: totalHt + 95)
        alertView.center = targetView.center
        backgroundView.addSubview(alertView)
        
        alertView.addSubview(titleLabel)
        alertView.addSubview(code)
        alertView.addSubview(nickHeader)
        alertView.addSubview(nick)
        alertView.addSubview(closeButton)
        targetView.bringSubviewToFront(backgroundView)
        
        //animate alertView in
        UIView.animate(withDuration: 0.5, animations: {
            self.alertView.isHidden = false
            self.alertView.alpha = 1.0
        })
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapExit))
        tap.numberOfTapsRequired = 1
        backgroundView.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }
    
    
    @objc func dismissAlert() {
        UIView.animate(withDuration: 0.5, animations: {
            self.alertView.alpha = 0.0
            NotificationCenter.default.removeObserver(self)
        }, completion: { done in
            if done {
                self.backgroundView.removeFromSuperview()
            }
        })
    }
    
    
}

