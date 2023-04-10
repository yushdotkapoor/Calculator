//
//  global.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/18/23.
//

import Foundation
import UIKit
import AVKit
import SwiftyJSON
import Firebase
import LocalAuthentication

let ref = Database.database().reference()
var downloadQueue:[String: (Message, ThreadUsers)] = [:]
var currentlyDownloading:[String] = []
var allKeys:[String] = []
var threadAggregators:[ThreadAggregator] = []

var myKey: String {
    get {
        return UserDefaults.standard.string(forKey: "key") ?? ""
    }
}

let notificationStyleDict = [
    "Calculator": [
        "title": "Calculator",
        "body": "Your calculation is complete",
    ],
    "Amazon": [
        "title": "Fill your basket with joy",
        "body": "Explore personalized finds for you",
    ],
    "Uber Eats": [
        "title": "Let's catch up",
        "body": "Head to the Uber eats app to see what's new"
    ],
    "Apple Wallet": [
        "title": "Daily Cash",
        "body": "You recieved $0.40 in Daily Cash yesterday and your month total is $3.78"
    ],
    "Instagram": [
        "title": "Instagram",
        "body": "sheyboss, josh_97, and taliabeckam liked your photo."
    ],
    "Netflix": [
        "title": "Pick up where you left off",
        "body": "Continue watching Gravity Watchers"
    ],
    "Photos": [
        "title": "New memory",
        "body": "Check out \"Autumn\""
    ],
    "Reddit": [
        "title": "facepalm:",
        "body": "Ready or not"
    ],
    "Yahoo": [
        "title": "Breaking News",
        "body": "Stocks open lower after ECB surprises with 0.50% rate hike"
    ],
    "YouTube": [
        "title": "Physics Girl",
        "body": "48 hours - the most isolated camp on earth"
    ],
].sorted(by: { $0.key < $1.key })


func keyGenerator(keyArrays:Array<String>) -> String {
    var string = ""
    var i = 0
    while i < 6 {
        let random = Int.random(in: 0..<10)
        string.append("\(random)")
        i += 1
    }
    if keyArrays.contains(string) {
        return keyGenerator(keyArrays: keyArrays)
    }
    return string
}


func userExists() -> Bool {
    return UserDefaults.standard.object(forKey: "exists") != nil
}

func updateFaceIdEntry() {
    let context = LAContext()
    var error: NSError?

    if !context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
        UserDefaults.standard.bool(forKey: "biometric")
    }
}


func updateCache() {
    threadAggregators = []
    ref.child("Users").observe(.value, with: { (snapshot) in
        guard let value = snapshot.value as? NSDictionary else { return }
        allKeys = value.allKeys as? [String] ?? []
        let jValue = JSON(value)
        guard let myInfo = jValue.first(where: { $0.0 == myKey }), let dict = myInfo.1.dictionary, let threads = dict["threads"]?.dictionaryObject else { return }
        
        var relevantUsers: [User] = []
        if !threads.isEmpty {
            relevantUsers.append(getUserFromDictionary(t: threads.first!, value: value, comparison: { $0.key == myKey }))
        }
        
        for t in threads {
            relevantUsers.append(getUserFromDictionary(t: t, value: value, comparison: { $0.key != myKey }))
        }
        
        UserDefaults.standard.setValue(try! PropertyListEncoder().encode(relevantUsers), forKey: "relevantUsers")
        UserDefaults.standard.setValue(threads, forKey: "threads")
        
        let unread = JSON(threads).filter({ $0.1.dictionaryValue["uids"]!.dictionaryValue.contains(where: { $0.key == myKey && $0.value.boolValue }) })
        UIApplication.shared.applicationIconBadgeNumber = unread.isEmpty ? 0 : 1
        
        updateThreadsIfNeeded(threads: threads)
    })
}

func updateThreadsIfNeeded(threads: [String: Any]) {
    for threadID in threads.keys {
        if !threadAggregators.contains(where: { $0.selectedThread == threadID }) {
            if let relevantUsers = UserDefaults.standard.data(forKey: "relevantUsers"), let threadData = threads[threadID] as? [String: Any], let uids = threadData["uids"] as? [String: Bool] {
                do {
                    let usrs = try PropertyListDecoder().decode([User].self, from: relevantUsers)
                    let threadUsers = ThreadUsers(me: usrs.first(where: { $0.senderId == myKey })!, them: usrs.first(where: { $0.senderId == uids.keys.first(where: { $0 != myKey }) })!)
                    let threadAggregator = ThreadAggregator(selectedThread: threadID, threadUsers: threadUsers)
                    threadAggregator.listen()
                    threadAggregators.append(threadAggregator)
                } catch {
                    print("Error in retrieving relevantUsers")
                }
            }
        }
    }
}

func getUserFromDictionary(t: (key: String, value: Any), value: NSDictionary, comparison: ((key: String, value: Bool)) throws -> Bool) -> User {
    if let t_value = t.value as? [String: Any], myKey != "" {
        let uids = t_value["uids"]! as? [String: Bool] ?? [:]
        let uid = try? uids.first(where: comparison)
        let otherUserInfo = value[uid!.key] as? [String: Any] ?? [:]
        let nick = t_value["nick"]! as? String ?? uid!.key
        var nicknames = UserDefaults.standard.dictionary(forKey: "aliases") as? [String: String] ?? [:]
        let nickDe = 🤣(🌩: nick, 🐔: "987654", 🐚: "123456", 🐉: Date(timeIntervalSince1970: 0), 🐳: "nick \(t.key)")
        nicknames[uid!.key] = nickDe
        UserDefaults.standard.setValue(nicknames, forKey: "aliases")
        
        return User(notifyWithSender: otherUserInfo["notifyWithSender"] as? String, notifyWithBody: otherUserInfo["notifyWithBody"] as? String, senderId: uid!.key, displayName: nickDe, token: otherUserInfo["token"] as? String)
    }
    return User(senderId: "", displayName: "")
}

func isView(selfView: UIViewController, checkView: AnyClass) -> Bool {
    if let viewController = selfView.navigationController?.visibleViewController {
        if viewController.isKind(of: checkView.self) {
            return true
        }
        return false
    }
    return false
}

func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.impactOccurred()
}

func impact(style: UINotificationFeedbackGenerator.FeedbackType) {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(style)
}


func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
    let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
    label.numberOfLines = 0
    label.font = font
    label.font = label.font.withSize(font.pointSize + 1)
    label.text = text
    
    label.sizeToFit()
    return label.frame.height
}

func changeIcon(name: String) {
    if UIApplication.shared.supportsAlternateIcons, let _ = UIImage(named: name) {
        UIApplication.shared.setAlternateIconName(name, completionHandler: { error in
            if let error = error {
                print("Failed to change app icon: \(error.localizedDescription)")
            } else {
                print("Changed app icon successfully")
            }
        })
    }
}


func getFileURL(for fileName: String) -> URL? {
    let fileManager = FileManager.default
    guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return nil // failed to get document directory
    }
    let fileURL = documentDirectory.appendingPathComponent(fileName)
    guard fileManager.fileExists(atPath: fileURL.path) else {
        return nil // file does not exist
    }
    return fileURL
}

func fileExists(fileName: String) -> Bool {
    let fileManager = FileManager.default
    guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return false // failed to get document directory
    }
    let fileURL = documentDirectory.appendingPathComponent(fileName)
    return fileManager.fileExists(atPath: fileURL.path)
}


func generateThumbnailImage(fileName: String, completion: @escaping (UIImage?) -> Void) {
    let tempFileName = "\(fileName).mp4"
    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tempFileName)
    do {
        if let fileURL = getFileURL(for: fileName) {
            let urlData = try Data(contentsOf: fileURL)
            try urlData.write(to: tempURL, options: .atomic)
            let asset = AVAsset(url: tempURL)
            let assetImageGenerator = AVAssetImageGenerator(asset: asset)
            
            // Set the maximum size of the thumbnail image
            let maxSize = CGSize(width: 720, height: 720)
            assetImageGenerator.maximumSize = maxSize
            
            // Get the time for the middle of the video
            let duration = asset.duration
            let middleTime = CMTimeMultiplyByFloat64(duration, multiplier: 0.5)
            
            // Generate the thumbnail image
            assetImageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: middleTime)]) { _, cgImage, _, _, _ in
                guard let cgImage = cgImage else {
                    completion(nil)
                    return
                }
                let thumbnailImage = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    completion(thumbnailImage)
                }
            }
        }
    } catch {
        print("ERROR in a lot of things but I am too lazy: \(error)")
    }
}


func getTopViewController() -> UIViewController? {
    guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
        return nil
    }
    var topViewController: UIViewController? = window.rootViewController
    while let presentedViewController = topViewController?.presentedViewController {
        topViewController = presentedViewController
    }
    if let tabBarController = topViewController as? UITabBarController,
       let selectedViewController = tabBarController.selectedViewController {
        topViewController = selectedViewController
    }
    if let navigationController = topViewController as? UINavigationController,
       let visibleViewController = navigationController.visibleViewController {
        topViewController = visibleViewController
    }
    return topViewController
}

func openSettings() {
    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
        // Check if the app is authorized for push notifications
        if let appSettings = URL(string: UIApplication.openSettingsURLString + Bundle.main.bundleIdentifier!) {
            if UIApplication.shared.canOpenURL(appSettings) {
                // Open the app's settings in the settings app
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
        } else {
            // If the app settings URL is invalid, just open the settings app
            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
        }
    }
}
