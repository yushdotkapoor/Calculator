//
//  ChatViewController.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 1/19/21.
//

import UIKit
import Firebase
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit
import Photos

struct Sender: SenderType {
    var senderId: String
    var displayName: String
}

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    var data: String
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

struct Link: LinkItem {
    var text: String?
    var attributedText: NSAttributedString?
    var url: URL
    var title: String?
    var teaser: String
    var thumbnailImage: UIImage
}

var imagePicker: UIImagePickerController!

let notification = PushNotificationSender()



class ChatViewController: MessagesViewController {
    
    var otherUserToken = ""
    
    var currentUser = Sender(senderId: "self", displayName: "Sender")
    var otherUser = Sender(senderId: "other", displayName: "Recipient")
    
    var messages = [Message]()
    
    var notifyWithSender = false
    var notifyWithBody = false
    
    let plzWaitPhoto = "https://firebasestorage.googleapis.com/v0/b/calculator-a6d61.appspot.com/o/please_wait%2FScreen%20Shot%202021-02-05%20at%2012.08.53%20AM.png?alt=media&token=4506ecfe-1837-499c-9473-8949c180e9cb"
    let plzWaitVideo = "https://firebasestorage.googleapis.com/v0/b/calculator-a6d61.appspot.com/o/please_wait%2Fplease_wait_vid.mov?alt=media&token=0b5f6f41-743a-47c8-b0b7-602a3eeb7a5b"
    
    var removalIndex:[Int] = []
    
    var lockOn = false
    
    var msgLimit = 30
    let limitCoefficient = 30
    
    var infoCard:customInformationCard?
    
    private(set) lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(loadMoreMessages), for: .valueChanged)
        return control
    }()
    
    @objc func info() {
        infoCard = customInformationCard()
        infoCard?.showAlert(userCode: selectedUser, viewController: self)
    }
    
    func dismissAlert() {
        infoCard?.dismissAlert()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentUser.displayName = myKey
        otherUser.displayName = selectedUser
        currentUser.senderId = myKey
        otherUser.senderId = selectedUser
        removalIndex.removeAll()
        
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(self.info))
        
        
        ref.child("users/\(selectedUser)/Notifcations/token").observeSingleEvent(of: .value, with: { (snapshot) in
            let val = snapshot.value as? String ?? ""
            self.otherUserToken = val
        })
        
        setNotificationSettings(event: .childAdded)
        setNotificationSettings(event: .childChanged)
        
        trashCan()
        removeAvatar()
        listen()
        
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.refreshControl = refreshControl
        
        self.showMessageTimestampOnSwipeLeft = true
        
        messagesCollectionView.contentInset.top += 10
        
        scrollsToLastItemOnKeyboardBeginsEditing = true
        
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        
        let saveItem = UIMenuItem(title: "Save", action: #selector(MessageCollectionViewCell.saveMedia(_:)))
        let shareItem = UIMenuItem(title: "Share", action: #selector(MessageCollectionViewCell.shareMedia(_:)))
        UIMenuController.shared.menuItems = [saveItem, shareItem]
    }
    
    func trashCan() {
        ref.child("users/\(myKey)/threads/\(selectedThread)/messages/0").removeValue()
        //ref.child("users/\(myKey)/threads/\(selectedThread)/messages").removeValue()
    }
    
    @objc func loadMoreMessages() {
        impact(style: .heavy)
            
        var vishmaArray:[[String:String]] = []
        msgLimit += limitCoefficient
        
        var maxCount = msgLimit
        
        ref.child("users/\(myKey)/threads/\(selectedThread)/messages").observe(.value, with: { [self] (snapshot) in
            maxCount = Int(snapshot.childrenCount)
            if msgLimit > maxCount {
                msgLimit = maxCount
            }
        })
        
        
        ref.child("users/\(myKey)/threads/\(selectedThread)/messages").queryLimited(toLast: UInt(msgLimit)).observe(.childAdded, with: { [self] (snapshot) in
            
            if isView(selfView: self, checkView: ChatViewController.self) {
                let thing = snapshot.value as? [String:String] ?? ["":""]
                if thing["id"] != nil {
                vishmaArray.append(thing)
                
                if vishmaArray.count == msgLimit {
                    passOn(a: vishmaArray)
                }
                }
            }
        })
    }
    
    func passOn(a: [[String:String]]) {
        var full:[Message] = []
        for n in a {
            let m = convertToMessage(thing: n)
            full.append(m)
        }
        let sortedFull = full.sorted{$0.sentDate < $1.sentDate}
        
        messages.removeAll()
        
        for f in sortedFull {
            messages.append(f)
            if f.messageId == sortedFull.last?.messageId {
                reload(scroll: false)
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func convertToMessage(thing: [String:String]) -> Message {
        var sender = self.otherUser
        
        if self.currentUser.senderId == thing["sender"] ?? "" {
            sender = self.currentUser
        }
        
        let data = thing["data"] ?? ""
        let date = thing["date"] ?? ""
        let type = thing["type"] ?? ""
        let id = thing["id"] ?? ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss' 'Z"
        let convertedDate = dateFormatter.date(from: date)
       
        
        switch type {
        case "text":
            let mess = Message(sender: sender, messageId: id, sentDate: convertedDate ?? Date(), kind: .text("\(data)"), data: data)
            return mess
        case "photo":
            let placeHolder = UIImage(named: "download")!
            
            let media = Media(url: nil,
                              image: nil,
                              placeholderImage: placeHolder,
                              size: CGSize(width: 300, height: 300))
            
            let mess = Message(sender: sender, messageId: id, sentDate: convertedDate ?? Date(), kind: .photo(media), data: data)
            
            
            if data == plzWaitPhoto {
                removalIndex.append(messages.count)
            }
            
            return mess
        case "video":
            let placeHolder = UIImage(named: "download")!
            
            let media = Media(url: nil,
                              image: nil,
                              placeholderImage: placeHolder,
                              size: CGSize(width: 300, height: 300))
            
            let mess = Message(sender: sender, messageId: id, sentDate: convertedDate ?? Date(), kind: .video(media), data: data)
            
            if data == plzWaitVideo {
                removalIndex.append(messages.count)
            }
            
            return mess
        case "linkPreview":
            let data2 = data.replacingOccurrences(of: "https://", with: "")
            let data3 = data2.replacingOccurrences(of: "http://", with: "")
            let data4 = data3.replacingOccurrences(of: "www.", with: "")
            let url = "https://www.google.com/s2/favicons?domain=www.\(data4)"
            
            let link = Link(text: "", url: URL(string: "https://\(data4)")!, title: getTitleOfURL(webpage: data4), teaser: "", thumbnailImage: load(url: url))
            
            let mess = Message(sender: sender, messageId: id, sentDate: convertedDate ?? Date(), kind: .linkPreview(link), data: data)
            
            return mess
        default:
            //this should never return
            return Message(sender: sender, messageId: id, sentDate: convertedDate ?? Date(), kind: .linkPreview(Link(text: "", url: URL(string: "https://google.com")!, title: "This shouldn't display", teaser: "", thumbnailImage: UIImage(named: "download")!)), data: data)
        }
    }
    
    func setNotificationSettings(event: DataEventType) {
        ref.child("users/\(selectedUser)/Notifcations").observe(event, with: { (snapshot) in
            let val = snapshot.value as? String ?? ""
            let ke = snapshot.key
            
            if ke == "sender"{
                if val == "Y" {
                    self.notifyWithSender = true
                }
                else {
                    self.notifyWithSender = false
                }
            }
            else if ke == "body" {
                if val == "Y" {
                    self.notifyWithBody = true
                }
                else {
                    self.notifyWithBody = false
                }
            }
        })
    }
    
    
    @objc private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What would you like to attach?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default) { action in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .camera
                imagePicker.allowsEditing = false
                imagePicker.mediaTypes = ["public.movie", "public.image"]
                imagePicker.videoQuality = .typeHigh
                imagePicker.showsCameraControls = true
                
                
                self.present(imagePicker, animated: true, completion: nil)
            } else {
                self.alert(title: "Oh no!", message: "It seems that this device cannot access the camera.", actionTitle: "Okay")
            }
        })
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default) { action in
            imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = true
            imagePicker.mediaTypes = ["public.movie", "public.image"]
            imagePicker.videoQuality = .typeHigh
            
            self.present(imagePicker, animated: true, completion: nil)
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(actionSheet, animated: true)
    }
    
    var first = true
    
    func listen() {
        var lim:UInt?
        
        ref.child("users/\(myKey)/threads/\(selectedThread)/messages").observe(.value, with: { [self] (snapshot) in
            
            ref.child("users/\(myKey)/threads/\(selectedThread)/messages").queryLimited(toLast: lim ?? UInt(msgLimit)).observeSingleEvent(of: .value, with: { [self] (snapshot) in
                
                msgLimit = Int(lim ?? UInt(limitCoefficient))
                lim = UInt(msgLimit + 1)
                
                msgLimit = Int(snapshot.childrenCount)
                if isView(selfView: self, checkView: ChatViewController.self) {
                    if let thing = snapshot.value as? NSDictionary {
                        var keys = thing.allKeys as? [String]
                        keys!.sort()
                        if first {
                            for j in keys! {
                                let msg = thing[j] as! [String : String]
                                if msg["type"] == "photo" || msg["type"] == "video" {
                                    receiveMedia(snap: snapshot)
                                }
                                self.load(thing: msg)
                            }
                            first = false
                        } else {
                            let msg = thing[keys!.last!] as! [String : String]
                           
                            if msg["type"] == "photo" || msg["type"] == "video" {
                                receiveMedia(snap: snapshot)
                            }
                            self.load(thing: msg)
                        }
                    }
                }
            })
        })
    }
    
    
    func receiveMedia(snap: DataSnapshot) {
        if isView(selfView: self, checkView: ChatViewController.self) {
            if let snapVal = snap.value as? NSDictionary {
                var keys = snapVal.allKeys as? [String]
                keys!.sort()
                for j in keys! {
                    let thing = snapVal[j] as! [String : String]
                    
                    var sender = self.otherUser
                    
                    if self.currentUser.senderId == thing["sender"] ?? "" {
                        sender = self.currentUser
                    }
                    
                    let data = thing["data"] ?? ""
                    let date = thing["date"] ?? ""
                    let type = thing["type"] ?? ""
                    let id = thing["id"] ?? ""
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss' 'Z"
                    let convertedDate = dateFormatter.date(from: date)
                    
                    switch type {
                    case "photo":
                        guard let imageUrl = URL(string: data),
                              let placeholder = UIImage(systemName: "plus") else {
                            return
                        }
                
                        let media = Media(url: imageUrl,
                                          image: nil,
                                          placeholderImage: placeholder,
                                          size: CGSize(width: 300, height: 300))
                        
                        for i in self.removalIndex {
                            let messID = self.messages[i].messageId
                            if messID == id {
                                self.messages[i] = Message(sender: sender, messageId: id, sentDate: convertedDate ?? Date(), kind: .photo(media), data: "\(imageUrl)")
                                self.reload(scroll: true)
                            }
                        }
                        break
                        
                    case "video":
                        guard let imageUrl = URL(string: data),
                              let placeholder = UIImage(systemName: "plus") else {
                            return
                        }
                        
                        let media = Media(url: imageUrl,
                                          image: self.videoPreviewImage(url: imageUrl),
                                          placeholderImage: placeholder,
                                          size: CGSize(width: 300, height: 300))
                        
                        for i in self.removalIndex {
                            let messID = self.messages[i].messageId
                            if messID == id {
                                self.messages[i] = Message(sender: sender, messageId: id, sentDate: convertedDate ?? Date(), kind: .video(media), data: "\(imageUrl)")
                                self.reload(scroll: true)
                            }
                        }
                        break
                    default:
                        break
                    }
                }
            }
        }
    }
    
    
    
    func listen2() {
        
        ref.child("users/\(myKey)/threads/\(selectedThread)/messages").queryLimited(toLast: UInt(msgLimit)).observe(.childAdded, with: { (snapshot) in
            if isView(selfView: self, checkView: ChatViewController.self) {
                let thing = snapshot.value as? [String:String] ?? ["":""]
                self.load(thing: thing)
            }
        })
        
        ref.child("users/\(myKey)/threads/\(selectedThread)/messages").queryLimited(toLast: UInt(msgLimit + 1)).observe(.childChanged, with: { (snapshot) in
            self.msgLimit += 1
            if isView(selfView: self, checkView: ChatViewController.self) {
                let thing = snapshot.value as? [String:String] ?? ["":""]
                
                var sender = self.otherUser
                
                if self.currentUser.senderId == thing["sender"] ?? "" {
                    sender = self.currentUser
                }
                
                let data = thing["data"] ?? ""
                let date = thing["date"] ?? ""
                let type = thing["type"] ?? ""
                let id = thing["id"] ?? ""
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss' 'Z"
                let convertedDate = dateFormatter.date(from: date)
                
                switch type {
                case "photo":
                    guard let imageUrl = URL(string: data),
                          let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    let media = Media(url: imageUrl,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 300, height: 300))
                    
                    for i in self.removalIndex {
                        let messID = self.messages[i].messageId
                        if messID == id {
                            self.messages[i] = Message(sender: sender, messageId: id, sentDate: convertedDate ?? Date(), kind: .photo(media), data: "\(imageUrl)")
                            self.reload(scroll: true)
                        }
                    }
                    break
                    
                case "video":
                    guard let imageUrl = URL(string: data),
                          let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    let media = Media(url: imageUrl,
                                      image: self.videoPreviewImage(url: imageUrl),
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 300, height: 300))
                    
                    for i in self.removalIndex {
                        let messID = self.messages[i].messageId
                        if messID == id {
                            self.messages[i] = Message(sender: sender, messageId: id, sentDate: convertedDate ?? Date(), kind: .video(media), data: "\(imageUrl)")
                            self.reload(scroll: true)
                        }
                    }
                    
                    break
                default:
                    break
                    
                }
                
            }
        })
    }
    
    func delayLoad(count: Int, message: Message) {
        let imgURL = URL(string: message.data)!
        let placeholder = UIImage(systemName: "plus")
        var currentMessage = message
        var media = Media(url: imgURL,
                          image: nil,
                          placeholderImage: placeholder!,
                          size: CGSize(width: 300, height: 300))
        
        switch message.kind {
        case .photo(_):
            currentMessage.kind = .photo(media)
            break
        case .video(_):
            media.image = videoPreviewImage(url: imgURL)
            currentMessage.kind = .video(media)
            break
        default:
            break
        }
        
        self.messages[count] = currentMessage
        self.reload(scroll: false)
    }
    
    func vibrationLock() -> Bool {
        if lockOn {
            return false
        } else {
            lockOn = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                self.lockOn = false
            })
            return true
        }
    }
    
    func load(thing: [String:String]) {
        load(thing: thing, scrollable: true)
    }
    
    func load(thing: [String:String], scrollable: Bool) {
        var sender = self.otherUser
        
        
        if self.currentUser.senderId == thing["sender"] ?? "" {
            sender = self.currentUser
        }
        
            // if user sends message, vibrate lightly
            if sender.senderId == myKey {
                if vibrationLock() {
                    impact(style: .medium)
                }
            }
            else {
                //if other sends message, vibrate medium
                if vibrationLock() {
                    impact(style: .heavy)
                }
            
        }
        
        let mess = convertToMessage(thing: thing)
        
        if !scrollable {
        self.messages.insert(mess, at: 0)
        } else {
        self.messages.append(mess)
        }
        
        if messages.count == msgLimit {
            self.reload(scroll: scrollable)
        }
    }
    
    func getTitleOfURL(webpage: String) -> String {
        if let url = URL(string: "https://www.\(webpage)") {
            do {
                let contents = try String(contentsOf: url)
                let range = contents.endIndex(of: "<title>")
                let range2 = contents.index(of: "</title>")
                
                return String(contents[range!..<range2!])
            } catch {
                // contents could not be loaded
                return "\(url)"
            }
        } else {
            // the URL was bad!
            return "\(webpage)"
        }
    }
    
    func load(url: String) -> UIImage {
        let backup = UIImage(systemName: "safari")!
        if let url2 = URL(string: url) {
            if let data = try? Data(contentsOf: url2) {
                if let image = UIImage(data: data) {
                    return image
                }
                else {
                    return backup
                }
            }
            else {
                return backup
            }
        }
        else {
            return backup
        }
    }
    
    func videoPreviewImage(url: URL) -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        if let cgImage = try? generator.copyCGImage(at: CMTime(seconds: 0.0, preferredTimescale: 60), actualTime: nil) {
            return UIImage(cgImage: cgImage)
        }
        else {
            return nil
        }
    }
    
    func removeAvatar() {
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingAvatarSize = .zero
            layout.photoMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.photoMessageSizeCalculator.incomingAvatarSize = .zero
            layout.videoMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.videoMessageSizeCalculator.incomingAvatarSize = .zero
            layout.attributedTextMessageSizeCalculator.incomingAvatarSize = .zero
            layout.attributedTextMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.attributedTextMessageSizeCalculator.avatarLeadingTrailingPadding = .zero
            layout.linkPreviewMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.linkPreviewMessageSizeCalculator.incomingAvatarSize = .zero
        }
    }
    
    func reload(scroll: Bool) {
        ref.child("users/\(myKey)/threads/\(selectedThread)/recipients/\(myKey)").setValue("N")
        
        self.messagesCollectionView.reloadDataAndKeepOffset()
        
        if scroll {
            self.messagesCollectionView.scrollToLastItem(animated: true)
        }
    }
    
    func hasLink(input: String, type: String) -> Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        
        let matches = detector.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
        
        let checkForEmail = input.isValidEmail()
        
        let count = matches.count
        
        if count == 0 || type == "photo" || type == "video" || checkForEmail {
            return false
        }
        else {
            var lowerBound = input.firstIndex(of: input.first!)!
            var inputs:[String:[Bool:String]] = [:]
            for match in matches {
                let range = Range(match.range, in: input)!
                
                let before = input[lowerBound..<range.lowerBound]
                let link = input[range]
                
                if !before.isEmpty {
                    inputs[String(before)] = [false:"before"]
                }
                
                
                inputs[String(link)] = [true:"none"]
                lowerBound = range.upperBound
                
                
                if match.isEqual(matches.last) {
                    let after = input[lowerBound...]
                    if !after.isEmpty {
                        inputs[String(after)] = [false:"after"]
                    }
                }
            }
            let now = Date()
            for t in inputs {
                let s = t.key
                let b = t.value.first!.key
                let v = t.value.first!.value
                
                if b {
                    let newDate = now.betterDate()
                    let link = Link(text: "", url: URL(string: "https://\(s)")!, title: getTitleOfURL(webpage: s), teaser: "", thumbnailImage: load(url: s))
                    
                    let message = Message(sender: currentUser, messageId: "\(newDate)-\(UUID().uuidString)", sentDate: Date(), kind: .linkPreview(link), data: s)
                    
                    
                    let mess: [String: Any] = [
                        "data": message.data,
                        "id": message.messageId,
                        "sender": message.sender.senderId,
                        "type": "linkPreview",
                        "date": "\(message.sentDate)"
                    ]
                    
                    let otraKey = self.otherUser.senderId
                    
                    let both = [myKey, otraKey]
                    
                    for key in both {
                        ref.child("users/\(key)/threads/\(selectedThread)/messages/\(message.messageId)").setValue(mess)
                    }
                    
                    
                    ref.child("users/\(otraKey)/threads/\(selectedThread)/recipients/\(otraKey)").setValue("Y")
                    
                    var titl = "Calculator"
                    var body = "Your calculation is complete"
                    
                    if notifyWithSender {
                        titl = "\(myKey)"
                    }
                    if notifyWithBody {
                        body = "URL"
                    }
                    
                    
                    notification.sendPushNotification(to: self.otherUserToken, title: titl, body: body)
                    
                    self.messagesCollectionView.scrollToLastItem()
                    
                }
                else {
                    if v == "before" {
                        let date = now.addingTimeInterval(-0.1)
                        let newDate = date.betterDate()
                        
                        let message = Message(sender: currentUser, messageId: "\(newDate)-\(UUID().uuidString)", sentDate: Date(), kind: .text("\(s)"), data: s)
                        save(message)
                    }
                    else {
                        let date = now.addingTimeInterval(0.1)
                        let newDate = date.betterDate()
                        
                        let message = Message(sender: currentUser, messageId: "\(newDate)-\(UUID().uuidString)", sentDate: Date(), kind: .text("\(s)"), data: s)
                        save(message)
                    }
                }
            }
            return true
        }
    }
    
    func getStringKindFromObjectKind(message: Message) -> String {
        var offset = 0
        var findParentheses = false
        let kind = "\(message.kind)"
        
        while !findParentheses {
            if kind.substring(with: offset..<(offset + 1)) == "(" {
                findParentheses = true
            }
            else {
                offset += 1
            }
        }
        
        let sub = kind.prefix(offset)
        return String(sub)
    }
    
    
    private func save(_ message: Message) {
        let text = message.data
        
        let sub = getStringKindFromObjectKind(message: message)
        
        if !hasLink(input: text, type: String(sub)) {
            
            let mess: [String: Any] = [
                "data": message.data,
                "id": message.messageId,
                "sender": message.sender.senderId,
                "type": sub,
                "date": "\(message.sentDate)"
            ]
            
            let both = [myKey, self.otherUser.senderId]
            
            for key in both {
                ref.child("users/\(key)/threads/\(selectedThread)/messages/\(message.messageId)").setValue(mess)
            }
            
            let otraKey = self.otherUser.senderId
            
            ref.child("users/\(otraKey)/threads/\(selectedThread)/recipients/\(otraKey)").setValue("Y")
            
            var titl = "Calculator"
            var body = "Your calculation is complete"
            
            if notifyWithSender {
                titl = "\(myKey)"
            }
            if notifyWithBody {
                if sub == "photo"{
                    body = "Photo Message"
                }
                else if sub == "video" {
                    body = "Video Message"
                }
                else if sub == "linkPreview" {
                    body = "URL"
                }
                else {
                    body = "\(message.data)"
                }
            }
            
            notification.sendPushNotification(to: self.otherUserToken, title: titl, body: body)
            
            self.messagesCollectionView.scrollToLastItem()
            //msgLimit += 1
            
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        
        if action == #selector(MessageCollectionViewCell.saveMedia(_:)) {
            switch messages[indexPath.section].kind {
            case .photo(let media), .video(let media):
                if media.url == nil {
                    return false
                }
                else {
                    return true
                }
            default:
                return super.collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
            }
        } else if action == #selector(MessageCollectionViewCell.shareMedia(_:)) {
            switch messages[indexPath.section].kind {
            case .photo(let media):
                if media.url == nil {
                    return false
                }
                else {
                    return true
                }
            default:
                return super.collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
            }
        }
        else {
            return super.collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        
        if action == #selector(MessageCollectionViewCell.saveMedia(_:)) {
            switch messages[indexPath.section].kind {
            case .photo(let media):
                savePhoto(url: "\(media.url!)")
                break
            case .video(let media):
                DispatchQueue.global(qos: .background).async {
                    if let url = media.url, let urlData = NSData(contentsOf: url) {
                        let galleryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
                        let filePath="\(galleryPath)/nameX.mp4"
                        DispatchQueue.main.async {
                            urlData.write(toFile: filePath, atomically: true)
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL:
                                                                                        URL(fileURLWithPath: filePath))
                            }){
                                success, error in
                                if success {
                                    print("Succesfully Saved")
                                } else {
                                    self.alert(title: "Error", message: "Could not save video : \(error!.localizedDescription)", actionTitle: "Okay")
                                }
                            }
                        }
                    }
                }
                break
            default:
                break
            }
        } else if action == #selector(MessageCollectionViewCell.shareMedia(_:)) {
            switch messages[indexPath.section].kind {
            case .photo(let media):
                // image to share
                let image = load(url: "\(media.url!)")
                
                // set up activity view controller
                let imageToShare = [ image ]
                let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
                
                // present the view controller
                self.present(activityViewController, animated: true, completion: nil)
                
                break
            default:
                break
            }
        }
        else {
            super.collectionView(collectionView, performAction: action, forItemAt: indexPath, withSender: sender)
        }
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
        }.resume()
    }
    
    func savePhoto(url: String) {
        guard let yourImageURL = URL(string: url) else { return }
        
        getDataFromUrl(url: yourImageURL) { (data, response, error) in
            
            guard let data = data, let imageFromData = UIImage(data: data) else { return }
            
            DispatchQueue.main.async() {
                UIImageWriteToSavedPhotosAlbum(imageFromData, nil, nil, nil)
            }
        }
    }
}



extension ChatViewController: InputBarAccessoryViewDelegate {
    
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        let newDate = Date().betterDate()
        
        let message = Message(sender: currentUser, messageId: "\(newDate)-\(UUID().uuidString)", sentDate: Date(), kind: .text("\(text)"), data: text)
        
        save(message)
        
        inputBar.inputTextView.text = ""
        messagesCollectionView.scrollToLastItem(animated: true)
    }
}


extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        
        let placeholder = UIImage(systemName: "plus")
        let date = Date()
        let newDate = date.betterDate()
        
        var media = Media(url: URL(string: plzWaitPhoto),
                          image: nil,
                          placeholderImage: placeholder!,
                          size: .zero)
        
        let mID = "\(date)-\(UUID().uuidString)"
        
        let messageID = "\(newDate)-\(UUID().uuidString)"
        
        if let image = info[.editedImage] as? UIImage, let imageData =  image.pngData() {
            let fileName = "photo_message_" + mID.replacingOccurrences(of: " ", with: "——") + ".png"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                let tempMessage = Message(sender: self.currentUser,
                                          messageId: messageID,
                                          sentDate: date,
                                          kind: .photo(media),
                                          data: "\(self.plzWaitPhoto)")
                
                self.save(tempMessage)
                self.messagesCollectionView.scrollToLastItem(animated: true)
                
            }
            
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, completion: { [weak self] result in
                
                switch result {
                case .success(let urlString):
                    // Ready to send message
                    print("Uploaded Message Photo: \(urlString)")
                    
                    guard let url = URL(string: urlString) else {
                        return
                    }
                    
                    media.url = url
                    
                    let message = Message(sender: self!.currentUser,
                                          messageId: messageID,
                                          sentDate: date,
                                          kind: .photo(media),
                                          data: "\(urlString)")
                    
                    self?.save(message)
                    self?.messagesCollectionView.scrollToLastItem(animated: true)
                    
                    
                case .failure(let error):
                    print("message photo upload error: \(error)")
                    self?.alert(title: "Error", message: "The photo was unable to be sent. The problem could be your network connection.", actionTitle: "Okay")
                }
            })
        }
        else if let videoUrl = info[.mediaURL] as? URL {
            let vURL = createTemporaryURLforVideoFile(url: videoUrl as NSURL)
            let fileName = "photo_message_" + mID.replacingOccurrences(of: " ", with: "—") + ".mov"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                media.url = URL(string: self.plzWaitVideo)
                let tempMessage = Message(sender: self.currentUser,
                                          messageId: messageID,
                                          sentDate: date,
                                          kind: .video(media),
                                          data: self.plzWaitVideo)
                
                self.save(tempMessage)
            }
            
            // Upload Video
            
            StorageManager.shared.uploadMessageVideo(with: vURL as URL, fileName: fileName, completion: { [weak self] result in
                
                switch result {
                case .success(let urlString):
                    // Ready to send message
                    print("Uploaded Message Video: \(urlString)")
                    
                    guard let url = URL(string: urlString) else {
                        return
                    }
                    
                    media.url = url
                    
                    let message = Message(sender: self!.currentUser,
                                          messageId: messageID,
                                          sentDate: date,
                                          kind: .video(media),
                                          data: urlString)
                    
                    self?.save(message)
                    self?.messagesCollectionView.scrollToLastItem(animated: true)
                    
                case .failure(let error):
                    print("message photo upload error: \(error)")
                    self?.alert(title: "Error", message: "The video was unable to be sent. The problem could be your network connection.", actionTitle: "Okay")
                }
            })
        }
    }
    
    func createTemporaryURLforVideoFile(url: NSURL) -> NSURL {
        /// Create the temporary directory.
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        /// create a temporary file for us to copy the video to.
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(url.lastPathComponent ?? "")
        /// Attempt the copy.
        do {
            try FileManager().copyItem(at: url.absoluteURL!, to: temporaryFileURL)
        } catch {
            print("There was an error copying the video file to the temporary location.")
        }
        
        return temporaryFileURL as NSURL
    }
}


extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        return currentUser
    }
    
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        
        if isFromCurrentSender(message: message) {
            return UIColor(red: 239/255, green: 164/255, blue: 60/255, alpha: 1)
        }
        else {
            return UIColor(red: 50/255, green: 51/255, blue: 52/255, alpha: 1)
        }
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return UIColor.white
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
            break
        default:
            break
        }
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath,
                      in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        
        let futureIndex = indexPath.section + 1
        
        
        if futureIndex < messages.count {
            if isFromCurrentSender(message: message) {
                if isFromCurrentSender(message: messages[futureIndex]) {
                    return .bubble
                }
                else {
                    return .bubbleTail(.bottomRight, .curved)
                }
            }
            else {
                if isFromCurrentSender(message: messages[futureIndex]) {
                    return .bubbleTail(.bottomLeft, .curved)
                }
                else {
                    return .bubble
                }
            }
        }
        else {
            if isFromCurrentSender(message: message) {
                return .bubbleTail(.bottomRight, .curved)
            }
            else {
                return .bubbleTail(.bottomLeft, .curved)
            }
        }
    }
    
    func messageTimestampLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let sentDate = message.sentDate
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/YYYY h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        let dateString = formatter.string(from: sentDate)
        let timeLabelFont: UIFont = .boldSystemFont(ofSize: 10)
        let timeLabelColor: UIColor
        if #available(iOS 13, *) {
            timeLabelColor = .systemGray
        } else {
            timeLabelColor = .darkGray
        }
        return NSAttributedString(string: dateString, attributes: [.foregroundColor: timeLabelColor, .font: timeLabelFont])
    }
}

extension ChatViewController: MessageCellDelegate {
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            if media.url == nil {
                let ct = indexPath.section
                self.delayLoad(count: ct, message: message)
            }
            else {
                print("loaded")
                
                guard let imageUrl = media.url else {
                    return
                }
                
                let vc = PhotoViewerViewController(with: imageUrl)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            break
            
        case .video(let media):
            if media.url == nil {
                let ct = indexPath.section
                
                self.delayLoad(count: ct, message: message)
            }
            else {
                guard let videoUrl = media.url else {
                    return
                }
                let vc = AVPlayerViewController()
                vc.player = AVPlayer(url: videoUrl)
                present(vc, animated: true)
                break
            }
        default:
            break
        }
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .linkPreview(let link):
            UIApplication.shared.open(link.url)
            break
        default:
            break
        }
    }
    
}

extension MessageCollectionViewCell {
    @objc func saveMedia(_ sender: Any?) {
        if let collectionView = self.superview as? UICollectionView {
            // Get indexPath
            if let indexPath = collectionView.indexPath(for: self) {
                collectionView.delegate?.collectionView?(collectionView, performAction: #selector(MessageCollectionViewCell.saveMedia(_:)), forItemAt: indexPath, withSender: sender)
            }
        }
    }
    
    @objc func shareMedia(_ sender: Any?) {
        if let collectionView = self.superview as? UICollectionView {
            // Get indexPath
            if let indexPath = collectionView.indexPath(for: self) {
                collectionView.delegate?.collectionView?(collectionView, performAction: #selector(MessageCollectionViewCell.shareMedia(_:)), forItemAt: indexPath, withSender: sender)
            }
        }
    }
}
