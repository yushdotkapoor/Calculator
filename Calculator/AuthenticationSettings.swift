//
//  AuthenticationSettings.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/29/23.
//

import Foundation
import UIKit
import LocalAuthentication
import AVKit
import Speech

class AuthenticationSettings: UIViewController {
    
    @IBOutlet weak var faceIDSwitch: UISwitch!
    @IBOutlet weak var keyPhraseSwitch: UISwitch!
    @IBOutlet weak var BiometricText: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateAuthentication()
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            if context.biometryType == .faceID {
                BiometricText.text = "Use FaceID for Authentication"
            } else if context.biometryType == .touchID {
                BiometricText.text = "Use TouchID for Authentication"
            } else {
                BiometricText.isHidden = true
                faceIDSwitch.isHidden = true
            }
        } else {
            BiometricText.isHidden = true
            faceIDSwitch.isHidden = true
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateAuthentication()
    }
    
    
    func updateAuthentication() {
        DispatchQueue.main.async {
            self.faceIDSwitch.setOn(UserDefaults.standard.bool(forKey: "biometric"), animated: false)
            self.keyPhraseSwitch.setOn(UserDefaults.standard.bool(forKey: "keyPhraseActive"), animated: false)
        }
    }
    
    
    
    @IBAction func changePass(_ sender: Any) {
        if let vc = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(identifier: "onboard") as? Onboard {
            vc.task = .verifyPassword
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func changeKeyPhrase(_ sender: Any) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                SFSpeechRecognizer.requestAuthorization { status in
                    DispatchQueue.main.async {
                        if let vc = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(identifier: "passKeyView") as? PassKeyView {
                            vc.authentication = false
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
            } else {
                self.alert(title: "Error", message: "Microphone permissions have been denied, would you like to change this?", actions: [("No", (UIAlertAction.Style.cancel, {})), ("Yes", (UIAlertAction.Style.default, {
                    openSettings()
                }))])
                print("Microphone permission denied.")
            }
        }
    }
    
    
    @IBAction func faceIDToggle(_ sender: Any) {
        let context = LAContext()
        var error: NSError?
        
        if faceIDSwitch.isOn {
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                var localizedReason = "Authenticate with FaceID"
                if context.biometryType == .touchID {
                    localizedReason = "Authenticate with TouchID"
                }
                
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: localizedReason) { success, error in
                    UserDefaults.standard.setValue(success, forKey: "biometric")
                    self.updateAuthentication()
                }
            } else {
                alert(title: "Error", message: "This Device does not have the capability to use biometric authentication", actionTitle: "Okay")
                UserDefaults.standard.setValue(false, forKey: "biometric")
                self.updateAuthentication()
            }
        } else {
            UserDefaults.standard.setValue(false, forKey: "biometric")
            self.updateAuthentication()
        }
    }
    
    @IBAction func keyPhraseToggle(_ sender: Any) {
        if keyPhraseSwitch.isOn {
            changeKeyPhrase(self)
        } else {
            UserDefaults.standard.set(false, forKey: "keyPhraseActive")
        }
    }
}
