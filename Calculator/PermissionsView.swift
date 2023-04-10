//
//  PermissionsView.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/22/23.
//

import Foundation
import UIKit
import Firebase
import AVFoundation
import Speech

class PermissionsView: UIViewController {
    
    @IBOutlet weak var isNotificationsEnabled: UILabel!
    @IBOutlet weak var isCameraEnabled: UILabel!
    @IBOutlet weak var isMicrophoneEnabled: UILabel!
    @IBOutlet weak var isSpeechEnabled: UILabel!
    @IBOutlet weak var cameraTitle: UILabel!
    @IBOutlet weak var notificationsTitle: UILabel!
    @IBOutlet weak var microphoneTitle: UILabel!
    @IBOutlet weak var speechTitle: UILabel!
    
    var notificationDenied:Bool!
    var cameraDenied:Bool!
    var microphoneDenied:Bool!
    var speechDenied:Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeDisplayLabels()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        changeDisplayLabels()
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func appWillEnterForeground() {
        changeDisplayLabels()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    func changeDisplayLabels() {
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    self.isNotificationsEnabled.text = settings.authorizationStatus == .authorized ? "🟢" : "🔴"
                    self.notificationsTitle.textColor = settings.authorizationStatus == .authorized ? .label : .red
                    self.notificationDenied = settings.authorizationStatus == .denied
                }
            }
            let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            self.isCameraEnabled.text = cameraAuthorizationStatus == .authorized ? "🟢" : "🔴"
            self.cameraTitle.textColor = cameraAuthorizationStatus == .authorized ? .label : .red
            self.cameraDenied = cameraAuthorizationStatus == .denied
            
            let microphoneAuthorizationStatus = AVAudioSession.sharedInstance().recordPermission
            self.isMicrophoneEnabled.text = microphoneAuthorizationStatus == .granted ? "🟢" : "🔴"
            self.microphoneTitle.textColor = microphoneAuthorizationStatus == .granted ? .label : .red
            self.microphoneDenied = microphoneAuthorizationStatus == .denied
            
            let speecchAuthorizationStatus = SFSpeechRecognizer.authorizationStatus()
            self.isSpeechEnabled.text = speecchAuthorizationStatus == .authorized ? "🟢" : "🔴"
            self.speechTitle.textColor = speecchAuthorizationStatus == .authorized ? .label : .red
            self.speechDenied = speecchAuthorizationStatus == .denied
        }
    }
    
    func goToOnboard() {
        if let vc = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(identifier: "onboard") as? Onboard {
            vc.task = .choosePassword
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    @IBAction func enablePushNotifications(_ sender: Any) {
        if notificationDenied {
            openSettings()
        } else {
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions,completionHandler: {_, _ in
                self.changeDisplayLabels()
            })
            
            UserDefaults.standard.setValue("\(Messaging.messaging().fcmToken ?? "")", forKey: "token")
        }
    }
    
    @IBAction func enableCameraPermissions(_ sender: Any) {
        if cameraDenied {
            openSettings()
        } else {
            AVCaptureDevice.requestAccess(for: .video) { _ in
                self.changeDisplayLabels()
            }
        }
    }
    
    @IBAction func enableMicrophonePermissions(_ sender: Any) {
        if microphoneDenied {
            openSettings()
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission() { _ in
                self.changeDisplayLabels()
            }
        }
    }
    
    @IBAction func enableSpeechPermissions(_ sender: Any) {
        if speechDenied {
            openSettings()
        } else {
            SFSpeechRecognizer.requestAuthorization { _ in
                self.changeDisplayLabels()
            }
        }
    }
    
    
    @IBAction func nextPressed(_ sender: Any) {
        if !userExists() {
            if self.isNotificationsEnabled.text == "🔴" || self.isCameraEnabled.text == "🔴" {
                alert(title: "Wait!", message: "Leaving with disabled permissions may reduce security and experience! Are you sure you want to leave?", actions: [("Yes", (UIAlertAction.Style.default, { self.goToOnboard() })), ("No", (UIAlertAction.Style.default, {
                    openSettings()
                }))])
            } else {
                goToOnboard()
            }
        } else {
            for controller in navigationController?.viewControllers ?? [] {
                if let controller = controller as? Profile {
                    navigationController?.popToViewController(controller, animated: true)
                }
            }
        }
    }
    
    @IBAction func backPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
