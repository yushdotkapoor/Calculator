//
//  AppDelegate.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 1/19/21.
//

import UIKit
import Firebase
import AVFoundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        
        Auth.auth().signInAnonymously()
        
        updateFaceIdEntry()
        updateCache()
        
        
//        testCredentials()
        
//        if let fileUrl = getFileURL(for: "messages.json") {
//            do {
//                try FileManager.default.removeItem(at: fileUrl)
//            } catch {
//                print("error in deleting \(error)")
//            }
//        }
        
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        
        UserDefaults.standard.setValue("\(Messaging.messaging().fcmToken ?? "")", forKey: "token")
        
        return true
    }
    
    func testCredentials() {
        t(s: "Hello World!")
        t(s: "Crafty fellow")
        t(s: "He has no idea what is coming for him, and he does not desire anything but food")
        t(s: "")
        t(s: "🥲")
        t(s: "this was cool🥲 I wonder if ` all ranged of this \n are supported? ~ I hope so ")
        t(s: "\n")
        t(s: "\0")
        t(s: "gravitatinal levity has\0 no effect on this I hope")
        t(s: "Let's make this as obnoxiously long as possible. i wonder if emojis are supported. They may not be, and that would suck, but I suppose we could wait and see. It's not abnormal to be curious actually. It's more of a human state than an abnormality.")
        
        
//        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//        let fileURL = documentsDirectory.appendingPathComponent("pm_1680368893828-AD43719D-53C1-4A60-8179-687BCB2238CE.txt")
//
//        let img = UIImage(contentsOfFile: fileURL.path())!
//        if let imgData = img.jpegData(compressionQuality: 1.0) {
//            let imgStr = imgData.base64EncodedString()
//            t(s: imgStr, ez: true)
//        }
        
    }
    
    
    func t(s: String, ez: Bool = false) {
        let id1 = "357843"
        let id2 = "979454"
        var dt = Date.now
        var sc = UUID().uuidString
        dt = Date(timeIntervalSince1970: 192304938)
        sc = "USD8-HFIUS7b-HF8H-HSI89-37HF"
        let en = 😂(🥮: s, 🥛: id1, 🎂: id2, 🍟: dt, 🫐: sc, ez: ez)
        print("\(s) encoded -> \(en)")
        let de = 🤣(🌩: en, 🐔: id1, 🐚: id2, 🐉: dt, 🐳: sc, ez: ez)
        if s != de {
            print("\n-ERROR-\nDate: \(dt.timeIntervalSince1970)\nsc: \(sc)\nstring: \(s)\nunknown: \(de)")
        } else {
            print("Success \(de)")
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if myKey != "", let fcmToken = fcmToken {
            ref.child("Users").child(myKey).child("token").setValue(fcmToken)
        }
        print("Received FCM token: \(fcmToken ?? "")")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("applicationWillResignActive")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("applicationDidEnterBackground")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("applicationWillTerminate")
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        // Handle the push notification
        if let _ = getTopViewController() as? ChatViewController { return }
        impact(style: .medium)
    }
}
