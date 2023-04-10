//
//  Onboard.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/18/23.
//

import UIKit
import Firebase
import LocalAuthentication
import AVFoundation


class Login: Codable {
    var time: Double
    var result: Bool
    var fileName: String?
    
    init(time: Double, result: Bool, fileName: String? = nil) {
        self.time = time
        self.result = result
        self.fileName = fileName
    }
}


class Onboard: UIViewController, AVCapturePhotoCaptureDelegate {
    enum Task {
        case entry
        case choosePassword
        case updatePassword
        case confirmPassword
        case verifyPassword
        
        var title: String {
            switch self {
            case.entry:
                return ""
            case .choosePassword:
                return "Choose a numerical password and press the equals sign when finished"
            case .updatePassword:
                return "Choose New Password"
            case .confirmPassword:
                return "Confirm your password"
            case .verifyPassword:
                return "Enter your current password"
            }
        }
        
        var nextTask: Task? {
            switch self {
            case .choosePassword:
                return .confirmPassword
            case .updatePassword:
                return .confirmPassword
            case .confirmPassword, .entry:
                return nil
            case .verifyPassword:
                return .choosePassword
            }
        }
        
        var prevTask: Task? {
            switch self {
            case .choosePassword, .verifyPassword, .entry:
                return nil
            case .updatePassword:
                return .verifyPassword
            case .confirmPassword:
                return .choosePassword
            }
        }
    }
    
    var captureSession = AVCaptureSession()
    var stillImageOutput = AVCaptureStillImageOutput()
    var frontCamera: AVCaptureDevice?
    
    var task: Task? = Onboard.Task.entry
    
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    var justStarted = true
    var changePasswordSegue = false
    var entranceSegue = false
    var keepTrack = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.setValue("\(Messaging.messaging().fcmToken ?? "")", forKey: "token")
        
        if !userExists() && task == .entry {
            task = Onboard.Task.choosePassword
            if let vc = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(identifier: "welcome") as? WelcomeView {
                navigationController?.pushViewController(vc, animated: true)
            }
            return
        }
        
        beginTask()
        setupCaptureSkeleton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        navigationController?.navigationBar.isHidden = false
    }
    
    func conductFaceID(context: LAContext) {
        var localizedReason = "Authenticate with FaceID"
        if context.biometryType == .touchID {
            localizedReason = "Authenticate with TouchID"
        }
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: localizedReason) { [self] success, error in
            if error != nil {
                task = .entry
                DispatchQueue.main.async {
                    self.beginTask()
                }
                return
            }
            if success {
                DispatchQueue.main.async {
                    if UserDefaults.standard.bool(forKey: "keyPhraseActive") && UserDefaults.standard.string(forKey: "keyPhrase") ?? "" != "" {
                        print(UserDefaults.standard.string(forKey: "keyPhrase"))
                        self.conductKeyPhrase()
                    } else {
                        self.performSegue(withIdentifier: "onboardToMessageView", sender: self)
                    }
                }
            }
        }
    }
    
    func conductKeyPhrase() {
        if let vc = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(identifier: "passKeyView") as? PassKeyView {
            vc.authentication = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func beginTask() {
        label.text = "0"
        keepTrack = ""
        justStarted = true
        header.text = task?.title
        
        if task == nil {
            if changePasswordSegue {
                self.dismiss(animated: true) { [self] in
                    backButton.isHidden = task == .entry
                }
            } else if entranceSegue {
                let context = LAContext()
                var error: NSError?
                print(UserDefaults.standard.string(forKey: "keyPhrase"))
                if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) && UserDefaults.standard.bool(forKey: "biometric") {
                    conductFaceID(context: context)
                } else if UserDefaults.standard.bool(forKey: "keyPhraseActive") && UserDefaults.standard.string(forKey: "keyPhrase") ?? "" != "" {
                    task = .entry
                    print(UserDefaults.standard.string(forKey: "keyPhrase"))
                    conductKeyPhrase()
                } else {
                    self.performSegue(withIdentifier: "onboardToMessageView", sender: self)
                }
            } else {
                self.performSegue(withIdentifier: "onboardToMessageView", sender: self)
            }
        } else {
            backButton.isHidden = task == .entry
        }
    }
    
    func setupCaptureSkeleton() {
        // Set up the capture session
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        // Find the front camera
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front)
        let devices = deviceDiscoverySession.devices
        for device in devices {
            if device.position == .front {
                frontCamera = device
            }
        }
        
        do {
            // Add the input from the front camera to the capture session
            guard let frontCamera = frontCamera else { return }
            let input = try AVCaptureDeviceInput(device: frontCamera)
            captureSession.addInput(input)
            captureSession.addOutput(stillImageOutput)
        } catch {
            print("Unable to access front camera.")
            return
        }
    }
    
    func takePictureAndSave(login: Login, completion: @escaping (String) -> Void) {
        // Capture a still image from the video feed
        if let videoConnection = stillImageOutput.connection(with: AVMediaType.video) {
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection) { [self] (sampleBuffer, error) -> Void in
                captureSession.stopRunning()
                if sampleBuffer != nil {
                    // Convert the image buffer to a UIImage object
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer!)
                    
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let fileName = "login_\(Int(login.time)).jpg"
                    let fileURL = documentsDirectory.appendingPathComponent(fileName)
                    
                    do {
                        try imageData?.write(to: fileURL)
                        completion(fileName)
                    } catch {
                        print("Error writing image data to file: \(error)")
                    }
                }
            }
        }
    }
    
    func zeroCheck() {
        if justStarted {
            label.text = ""
            justStarted = false
        }
    }
    
    func addToPassword(_ char: String) {
        keepTrack.append(char)
        if task == .entry {
            label.text?.append(rand())
        } else {
            label.text = keepTrack
        }
    }
    
    @IBAction func zero(_ sender: Any) {
        zeroCheck()
        addToPassword("0")
    }
    
    @IBAction func one(_ sender: Any) {
        zeroCheck()
        addToPassword("1")
    }
    
    @IBAction func two(_ sender: Any) {
        zeroCheck()
        addToPassword("2")
    }
    
    @IBAction func three(_ sender: Any) {
        zeroCheck()
        addToPassword("3")
    }
    
    @IBAction func four(_ sender: Any) {
        zeroCheck()
        addToPassword("4")
    }
    
    @IBAction func five(_ sender: Any) {
        zeroCheck()
        addToPassword("5")
    }
    
    @IBAction func six(_ sender: Any) {
        zeroCheck()
        addToPassword("6")
    }
    
    @IBAction func seven(_ sender: Any) {
        zeroCheck()
        addToPassword("7")
    }
    
    @IBAction func eight(_ sender: Any) {
        zeroCheck()
        addToPassword("8")
    }
    
    @IBAction func nine(_ sender: Any) {
        zeroCheck()
        addToPassword("9")
    }
    
    @IBAction func point(_ sender: Any) {
        keepTrack.append(".")
        label.text?.append(".")
    }
    
    func addLogin(login: Login) {
        var allLogins = [login]
        if let loginsCache = UserDefaults.standard.data(forKey: "logins") {
            do {
                let logins = try PropertyListDecoder().decode([Login].self, from: loginsCache)
                allLogins.append(contentsOf: logins)
            } catch {
                print("Error in retrieving logins")
            }
        }
        UserDefaults.standard.setValue(try! PropertyListEncoder().encode(allLogins), forKey: "logins")
    }
    
    @IBAction func enter(_ sender: Any) {
        switch task {
        case .entry:
            entranceSegue = true
            let temp = UserDefaults.standard.string(forKey: "Password")!
            let pass = 🤣(🌩: temp, 🐔: "123456", 🐚: "987654", 🐉: Date(timeIntervalSince1970: 0), 🐳: "passcode")
            if pass != keepTrack {
                if captureSession.isRunning {
                    break
                }
                var log = Login(time: Date().timeIntervalSince1970, result: false)
                guard let _ = frontCamera else {
                    addLogin(login: log)
                    break
                }
                
                DispatchQueue.global(qos: .background).async { [self, log] in
                    captureSession.startRunning()
                    takePictureAndSave(login: log) { [self, log] fileName in
                        log.fileName = fileName
                        addLogin(login: log)
                    }
                }
            } else {
                let log = Login(time: Date().timeIntervalSince1970, result: true)
                addLogin(login: log)
                task = task?.nextTask
            }
            beginTask()
            break
        case .verifyPassword:
            changePasswordSegue = true
            let temp = UserDefaults.standard.string(forKey: "Password")!
            let pass = 🤣(🌩: temp, 🐔: "123456", 🐚: "987654", 🐉: Date(timeIntervalSince1970: 0), 🐳: "passcode")
            if pass == keepTrack {
                impact(style: .success)
                task = task?.nextTask
            } else {
                impact(style: .error)
            }
            beginTask()
            break
        case .choosePassword, .updatePassword:
            if keepTrack.count < 4 || keepTrack.count > 12 {
                impact(style: .error)
                alert(title: "Error", message: "Password must be between 4 and 12 characters in length", actionTitle: "Okay")
            } else {
                let pass = 😂(🥮: label.text ?? "", 🥛: "123456", 🎂: "987654", 🍟: Date(timeIntervalSince1970: 0), 🫐: "passcode")
                impact(style: .success)
                UserDefaults.standard.setValue(pass, forKey: "tempPassword")
                task = task?.nextTask
            }
            beginTask()
            break
        case .confirmPassword:
            let temp = UserDefaults.standard.string(forKey: "tempPassword")!
            let pass = 🤣(🌩: temp, 🐔: "123456", 🐚: "987654", 🐉: Date(timeIntervalSince1970: 0), 🐳: "passcode")
            if pass != keepTrack {
                impact(style: .error)
                alert(title: "Error", message: "Passwords do not match, please try again", actionTitle: "Okay")
            } else if keepTrack.count < 4 || keepTrack.count > 12 {
                impact(style: .error)
                alert(title: "Error", message: "Password must be between 4 and 12 characters in length", actionTitle: "Okay")
            } else {
                let pass = 😂(🥮: keepTrack, 🥛: "123456", 🎂: "987654", 🍟: Date(timeIntervalSince1970: 0), 🫐: "passcode")
                UserDefaults.standard.setValue(pass, forKey: "Password")
                var successMessage = "Your user has been created."
                if !userExists() {
                    UserDefaults.standard.setValue(true, forKey: "exists")
                    let key = keyGenerator(keyArrays: allKeys)
                    UserDefaults.standard.setValue(key, forKey: "key")
                    let token = UserDefaults.standard.string(forKey: "token")
                    let noteDict = notificationStyleDict.first(where: { $0.key == "Calculator" })!
                    let data: [String : Any] = ["notifyWithBody": noteDict.value["body"]!, "notifyWithSender": noteDict.value["title"]!, "token": token ?? ""]
                    ref.child("Users").child(key).setValue(data)
                } else {
                    successMessage = "Your password has been updated."
                }
                impact(style: .success)
                alert(title: "Success", message: successMessage, actionTitle: "Okay") { [self] in
                    task = task?.nextTask
                    beginTask()
                }
                UserDefaults.standard.removeObject(forKey: "tempPassword")
            }
            beginTask()
            break
        case .none:
            break
        }
    }
    
    @IBAction func clear(_ sender: Any) {
        beginTask()
    }
    
    
    @IBAction func back(_ sender: Any) {
        task = task?.prevTask
        if task != nil {
            beginTask()
            return
        }
        navigationController?.popViewController(animated: true)
    }
    
    func rand() -> String {
        return String(Int.random(in: 0..<10))
    }
}


