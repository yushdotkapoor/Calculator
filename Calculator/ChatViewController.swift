//
//  ChatViewController.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/17/23.
//

import Foundation
import UIKit
import MessageKit
import Firebase
import InputBarAccessoryView
import AVKit
import SwiftyJSON
import TLPhotoPicker
import MobileCoreServices
import AudioKit
import AudioKitUI


class ChatViewController: MessagesViewController {
    
    let FIVE_MINUTES = 300.0
    
    private(set) lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(loadMoreMessages), for: .valueChanged)
        return control
    }()
    
    lazy var progressBar: UIProgressView = {
        let progressBar = UIProgressView(progressViewStyle: .default)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.tintColor = UIColor(red: 239/255, green: 164/255, blue: 60/255, alpha: 1)
        view.addSubview(progressBar)
        NSLayoutConstraint.activate([
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 4.0)
        ])
        return progressBar
    }()
    
    lazy var attachmentManager: AttachmentManager = { [unowned self] in
        let manager = AttachmentManager()
        manager.delegate = self
        return manager
    }()
    
    lazy var replyView: ReplyView = { [self] in
        let view = ReplyView()
        view.delegate = self
        view.isHidden = true
        messageInputBar.topStackView.addArrangedSubview(view)
        return view
    }()
    
    lazy var waveView: WaveFormView = {
        let waveView = WaveFormView()
//        waveView.frame = CGRect(x: 20, y: 100, width: 200, height: 100)
        waveView.backgroundColor = .gray
        waveView.isHidden = true
        view.addSubview(waveView)
        waveView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            waveView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            waveView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: -10),
            waveView.heightAnchor.constraint(equalToConstant: 50),
            waveView.widthAnchor.constraint(equalToConstant: 300),
        ])
        return waveView
    }()
    
    let deliveredText = NSMutableAttributedString(string: "Delivered", attributes: [
        .paragraphStyle: { () -> NSMutableParagraphStyle in
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .right
            return paragraphStyle
        }(), .font: UIFont.systemFont(ofSize: 10.0) ])
    
    let messageDeletedText = NSMutableAttributedString(string: "Message has been deleted", attributes: [
        .baselineOffset: 8,
        .font: UIFont.italicSystemFont(ofSize: 14.0),
        .foregroundColor: UIColor.white ])
    
    var messages:[Message] = [] {
        willSet {
            if messages.count != newValue.count {
                for (i, message) in newValue.enumerated() {
                    if i + 1 == newValue.count { break }
                    if message.sentDate + FIVE_MINUTES < newValue[i + 1].sentDate && sectionIndices.last! < (i + 1) {
                        sectionIndices.append(i + 1)
                    }
                }
            }
        }
        didSet {
            if oldValue.count != messages.count {
                self.runDownloads()
            }
            messagesCollectionView.reloadDataAndKeepOffset()
        }
    }
    
    var threadAggregator: ThreadAggregator!
    
    var sectionIndices:[Int] = [0]
    
    var infoCard:CustomInformationCard?
    
    var imagePicker: UIImagePickerController!
    
    struct UploadQueue {
        var queue:[Message] = []
        var uploading:Message?
    }
    
    var uploadQueue = UploadQueue()
    
    var firstTime = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ref.child("Users").child(threadAggregator.threadUsers.me.senderId).child("threads").child(threadAggregator.selectedThread).child("uids").child(threadAggregator.threadUsers.me.senderId).setValue(false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = threadAggregator.threadUsers.them.displayName
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(self.info))
        
        progressBar.isHidden = true
        
        setNotificationSettings()
        removeAvatar()
        
        messageInputBar.delegate = self
        messageInputBar.inputPlugins = [attachmentManager]
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.refreshControl = refreshControl
        
        self.showMessageTimestampOnSwipeLeft = true
        scrollsToLastItemOnKeyboardBeginsEditing = true
        
        let attachmentButton = InputBarButtonItem()
        attachmentButton.setSize(CGSize(width: 35, height: 35), animated: false)
        attachmentButton.setImage(UIImage(systemName: "paperclip"), for: .normal)
        attachmentButton.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
//        let microphoneButton = InputBarButtonItem()
//        microphoneButton.setSize(CGSize(width: 35, height: 35), animated: false)
//        microphoneButton.setImage(UIImage(systemName: "mic"), for: .normal)
//        microphoneButton.addAction(UIAction(handler: { _ in self.startRecording() }), for: .touchDown)
//        microphoneButton.addAction(UIAction(handler: { _ in self.stopRecording() }), for: .touchUpInside)
        
        let buttonStack = [attachmentButton]
        messageInputBar.setLeftStackViewWidthConstant(to: CGFloat(36 * buttonStack.count), animated: false)
//        messageInputBar.setStackViewItems([microphoneButton, attachmentButton], forStack: .left, animated: false)
        messageInputBar.setStackViewItems(buttonStack, forStack: .left, animated: false)
        
        DispatchQueue.main.async { [self] in
            UserDefaults.standard.addObserver(self, forKeyPath: threadAggregator.selectedThread, options: [.new], context: nil)
            UserDefaults.standard.addObserver(self, forKeyPath: "\(threadAggregator.selectedThread!)_delete", options: [.new], context: nil)
            observeValue(forKeyPath: threadAggregator.selectedThread, of: nil, change: nil, context: nil)
        }
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: threadAggregator.selectedThread)
        UserDefaults.standard.removeObserver(self, forKeyPath: "\(threadAggregator.selectedThread!)_delete")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == threadAggregator.selectedThread {
                var decodedMessages = threadAggregator.decodeMessageFile()
                decodedMessages = decodedMessages.filter({ msg in !messages.contains(where: { $0.messageId == msg.key }) })
                let decodedMsgs = Message.getMessages(fromDictionary: decodedMessages as NSDictionary, threadUsers: threadAggregator.threadUsers)
                decodedMsgs.forEach({
                    downloadQueue[$0.messageId] = ($0, self.threadAggregator.threadUsers)
                })
                messages.append(contentsOf: decodedMsgs)
                handleHaptics()
        } else if keyPath == "\(threadAggregator.selectedThread!)_delete" {
            let decodedMessages = threadAggregator.decodeMessageFile()
            if let delArr = UserDefaults.standard.array(forKey: "\(threadAggregator.selectedThread!)_delete") as? [String] {
                for mid in delArr {
                    let delDecoded = Message.getMessages(fromDictionary: [mid: decodedMessages[mid]!] as NSDictionary, threadUsers: threadAggregator.threadUsers)
                    messages.replaceElement(with: delDecoded.first!)
                }
                
                UserDefaults.standard.setValue(nil, forKey: "\(threadAggregator.selectedThread!)_delete")
                handleHaptics()
            }
        } else if let mid = uploadQueue.uploading?.messageId, keyPath == "uploadProgress_\(mid)" {
            var total = 0.0
            for message in uploadQueue.queue {
                total += UserDefaults.standard.double(forKey: "uploadProgress_\(message.messageId)")
            }
            DispatchQueue.main.async { [self] in
                setProgress(to: Float(total / Double(uploadQueue.queue.count)), completion: { [self] _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [self] in
                        if uploadQueue.queue.count == 0 {
                            UserDefaults.standard.removeObject(forKey: keyPath!)
                            progressBar.isHidden = true
                            progressBar.progress = 0.0
                        }
                    }
                })
            }
        }
    }
    
    func notify(message: Message) {
        ref.child("Users").child(threadAggregator.threadUsers.them.senderId).child("threads").child(threadAggregator.selectedThread).child("nick").observeSingleEvent(of: .value) { [self] snapshot in
            let snapVal = snapshot.value as? String ?? ""
            
            var titl = threadAggregator.threadUsers.them.notifyWithSender
            if titl == " " {
                titl = 🤣(🌩: snapVal, 🐔: "987654", 🐚: "123456", 🐉: Date(timeIntervalSince1970: 0), 🐳: "nick \(threadAggregator.selectedThread!)")
            }
            
            var body = threadAggregator.threadUsers.them.notifyWithBody
            if body == " " {
                let bodyDict = ["photo": "Photo Message", "video": "Video Message", "url": "URL", "linkPreview": "Link Message"]
                
                switch message.kind {
                case .text(let text), .emoji(let text):
                    body = text
                    break
                default:
                    body = bodyDict[message.kindString()]!
                    break
                }
            }
            
            PushNotificationSender.shared.sendPushNotification(to: threadAggregator.threadUsers.them.token!, title: titl!, body: body!)
        }
    }
    
    func setNotificationSettings() {
        ref.child("Users").child(threadAggregator.threadUsers.them.senderId).observe(.childChanged, with: { [self] (snapshot) in
            if let val = snapshot.value as? String {
                let ke = snapshot.key
                
                if ke == "notifyWithSender" {
                    threadAggregator.threadUsers.them.notifyWithSender = val
                } else if ke == "notifyWithBody" {
                    threadAggregator.threadUsers.them.notifyWithBody = val
                }
            }
        })
    }
    
    func removeAvatar() {
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageIncomingAvatarSize(.zero)
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageOutgoingAvatarSize(.zero)
        
        let bufferWidth = UIScreen.main.bounds.width * 0.25
        let paddingConstant:CGFloat = 10
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.setMessageIncomingMessageTopLabelAlignment(LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: paddingConstant, bottom: 0, right: bufferWidth)))
            layout.setMessageIncomingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: paddingConstant, bottom: 0, right: bufferWidth)))
            layout.setMessageOutgoingMessageTopLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: bufferWidth, bottom: 0, right: paddingConstant)))
            layout.setMessageOutgoingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: bufferWidth, bottom: 0, right: paddingConstant)))
        }
    }
    
    @objc func info() {
        infoCard = CustomInformationCard()
        infoCard?.showAlert(userCode: threadAggregator.threadUsers.them.senderId, viewController: self)
    }
    
    @objc func loadMoreMessages() {
        refreshControl.endRefreshing()
    }
    
    func startRecording() {
        print(inputContainerView)
        print(inputContainerView.frame)
        waveView.isHidden = false
    }
    
    func stopRecording() {
        waveView.isHidden = true
    }
    
    func runDownloads() {
        for dictStruct in downloadQueue.sorted(by: { $0.key > $1.key }) {
            let message = dictStruct.value.0
            if let media = message.getMedia() {
                guard !currentlyDownloading.contains(message.messageId) else { return }
                currentlyDownloading.append(message.messageId)
                CloudStorage.shared.downloadMedia(fileName: media.fileName!, message: message, threadUsers: dictStruct.value.1) { [self] result in
                    switch result {
                    case .failure(_):
                        break
                    case .success(let newMessage):
                        currentlyDownloading.removeAll(where: { $0 == message.messageId })
                        DispatchQueue.main.async { [self] in
                            messages.replaceElement(with: newMessage)
                            downloadQueue.removeValue(forKey: newMessage.messageId)
                        }
                        break
                    }
                }
            } else if let link = message.getLink() {
                guard !currentlyDownloading.contains(message.messageId) else { return }
                currentlyDownloading.append(message.messageId)
                link.getAttributes(mid: message.messageId) { [self] newLink in
                    DispatchQueue.main.async { [self] in
                        var message = message
                        message.kind = .linkPreview(newLink)
                        messages.replaceElement(with: message)
                        downloadQueue.removeValue(forKey: message.messageId)
                    }
                }
            } else {
                downloadQueue.removeValue(forKey: message.messageId)
            }
        }
    }
    
    func handleHaptics() {
        DispatchQueue.main.async { [self] in
            if navigationController?.topViewController != self { return }
            // handle vibrations
            if let l = messages.last {
                if l.sender.senderId == myKey {
                    impact(style: .light)
                } else {
                    impact(style: .rigid)
                }
            }
            
            if firstTime {
                firstTime = false
                messagesCollectionView.scrollToLastItem()
            }
        }
    }
    
    @objc private func presentInputActionSheet() {
        // TODO: Check if this is similar to Sona
        let actionSheet = UIAlertController(title: "Attach Media", message: "What would you like to attach?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default) { [self] action in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .camera
                imagePicker.allowsEditing = false
                imagePicker.mediaTypes = ["public.movie", "public.image"]
                imagePicker.videoQuality = .typeHigh
                imagePicker.showsCameraControls = true
                
                present(imagePicker, animated: true, completion: nil)
            } else {
                alert(title: "Oh no!", message: "It seems that this device cannot access the camera.", actionTitle: "Okay")
            }
        })
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default) { [self] action in
            let picker = TLPhotosPickerViewController()
            picker.delegate = self // set delegate
            picker.configure.singleSelectedMode = false
            picker.configure.allowedVideo = true
            picker.configure.allowedLivePhotos = false
            picker.configure.previewAtForceTouch = true
            
            present(picker, animated: true, completion: nil)
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(actionSheet, animated: true)
    }
}

extension ChatViewController: TLPhotosPickerViewControllerDelegate {
    func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool {
        // handle selected assets
        for asset in withTLPHAssets {
            var handled = false
            switch asset.type {
            case .photo:
                if let image = asset.fullResolutionImage {
                    handled = self.attachmentManager.handleInput(of: image)
                }
                break
            case .video:
                asset.tempCopyMediaFile() { url, _ in
                    handled = self.attachmentManager.handleInput(of: url as AnyObject)
                }
                break
            default:
                break
            }
            if !handled {
                print("There was an error transfering the image to the attachment manager")
            }
        }
        messagesCollectionView.scrollToLastItem()
        return true
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        
        var key = UIImagePickerController.InfoKey.editedImage
        if !info.keys.contains(key) {
            key = UIImagePickerController.InfoKey.originalImage
        }
        
        var handled = false
        if let image = info[key] as? UIImage {
            handled = self.attachmentManager.handleInput(of: image)
        } else if let videoURL = info[.mediaURL] as? URL {
            handled = self.attachmentManager.handleInput(of: videoURL as AnyObject)
        }
        
        if !handled {
            print("There was an error transfering the image to the attachment manager")
        }
    }
    
    func addToUploadQueue(message: Message) {
        progressBar.isHidden = false
        UserDefaults.standard.addObserver(self, forKeyPath: "uploadProgress_\(message.messageId)", options: [.new], context: nil)
        messages.append(message)
        downloadQueue[message.messageId] = (message, self.threadAggregator.threadUsers)
        runDownloads()
        
        uploadQueue.queue.append(message)
        handleUploadQueue()
    }
    
    func handleUploadQueue() {
        for message in uploadQueue.queue {
            if uploadQueue.uploading != nil { return }
            uploadQueue.uploading = message
            observeValue(forKeyPath: "uploadProgress_\(message.messageId)", of: nil, change: nil, context: nil)
            DispatchQueue.global(qos: .background).async { [self] in
                let kindEnum = message.kindEnum()
                if kindEnum == .photo || kindEnum == .video {
                    CloudStorage.shared.uploadMedia(message: message, threadUsers: threadAggregator.threadUsers) { [self] result in
                        switch result {
                        case .success(_):
                            uploadMessage(message: message)
                            break
                        case .failure(let err):
                            print("Error in uploading image: \(err)")
                            break
                        }
                    }
                } else {
                    uploadMessage(message: message)
                }
            }
        }
    }
    
    func setProgress(to progress: Float, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseInOut], animations: {
            self.progressBar.setProgress(progress, animated: true)
        }, completion: completion)
    }
    
    func uploadMessage(message: Message) {
        let msg = message.performPushModulations(threadUsers: threadAggregator.threadUsers)
        ref.child("Threads").child(threadAggregator.selectedThread).child("messages").child(msg.messageId).setValue(msg.databaseWorthy()) { [self] _, _ in
            UserDefaults.standard.setValue(1.0, forKey: "uploadProgress_\(message.messageId)")
            uploadQueue.queue.removeAll(where: { $0.messageId == message.messageId })
            UserDefaults.standard.removeObserver(self, forKeyPath: "uploadProgress_\(message.messageId)")
            uploadQueue.uploading = nil
            handleUploadQueue()
            messagesCollectionView.reloadDataAndKeepOffset()
        }
        ref.child("Users").child(threadAggregator.threadUsers.them.senderId).child("threads").child(threadAggregator.selectedThread).child("uids").child(threadAggregator.threadUsers.them.senderId).setValue(true)
        
        notify(message: message)
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.isHidden = true
    }
    
    func saveImageAndUpload(image: UIImage, rid: String?) {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else { return }
        let date = Date()
        let fileName = "pm_\(date.betterDate())-\(UUID().uuidString).txt"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        do {
            if !FileManager.default.fileExists(atPath: fileURL.path()) {
                try imageData.write(to: fileURL, options: .atomic)
                print("\(fileName) saved @ \(fileURL)")
            }
        } catch {
            print("Error in saving image to Application memory \(error)")
        }
        
        let media = Media(url: fileURL, fileName: fileName)
        let message = Message(sender: threadAggregator.threadUsers.me, sentDate: date, kind: .photo(media), replyTo: rid)
        addToUploadQueue(message: message)
    }
    
    func saveVideoAndUpload(videoURL: URL, rid: String?) {
        let date = Date()
        let fileName = "vm_\(date.betterDate())-\(UUID().uuidString).txt"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        var videoData = Data()
        do {
            videoData = try Data(contentsOf: videoURL)
            try videoData.write(to: fileURL, options: .atomic)
        } catch {
            print("There was an error copying the video file to the temporary location: \(error)")
        }
        
        let media = Media(url: fileURL, fileName: fileName)
        let message = Message(sender: threadAggregator.threadUsers.me, sentDate: date, kind: .video(media), replyTo: rid)
        addToUploadQueue(message: message)
    }
    
    func play(withData data: Data, name: String) {
        let videoFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(name).mp4")
        do {
            try data.write(to: videoFileURL, options: .atomic)
        } catch {
            print("Error saving video data to file: \(error.localizedDescription)")
        }
        
        let vc = AVPlayerViewController()
        vc.player = AVPlayer(url: videoFileURL)
        self.present(vc, animated: true) {
            vc.player?.play()
        }
    }
}

class ImageMediaItemSizeCalculator: CellSizeCalculator {
    private let message: MessageType
    private let maxWidth: CGFloat
    
    init(message: MessageType, maxWidth: CGFloat = UIScreen.main.bounds.width * 0.75) {
        self.message = message
        self.maxWidth = maxWidth
    }
    
    func cellSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        guard let message = message as? Message, let media = message.getMedia(), let mediaItem = media.image else { return .zero }
        
        let width = min(mediaItem.size.width, maxWidth)
        let height = mediaItem.size.height * (width / mediaItem.size.width)
        
        return CGSize(width: width, height: height)
    }
}


extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, ReplyViewDelegate {
    
    var currentSender: MessageKit.SenderType {
        return threadAggregator.threadUsers.me
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        let flattenedIndex = sectionIndices[indexPath.section] + indexPath.row
        var message = messages[flattenedIndex]
        if message.setData == "" {
            message.kind = .attributedText(messageDeletedText)
        }
        return message
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return sectionIndices.count
    }
    
    func numberOfItems(inSection section: Int, in messagesCollectionView: MessagesCollectionView) -> Int {
        let lastValue = section + 1 < sectionIndices.count ? sectionIndices[section + 1] : messages.count
        return lastValue - sectionIndices[section]
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let myColor = UIColor(red: 239/255, green: 164/255, blue: 60/255, alpha: 1)
        let theirColor = UIColor(red: 50/255, green: 51/255, blue: 52/255, alpha: 1)
        return isFromCurrentSender(message: message) ? myColor : theirColor
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return UIColor.white
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else { return }
        
        if message.kindEnum() == .photo, let media = message.getMedia() {
            guard let imageUrl = media.url else { return }
            imageView.image = UIImage(contentsOfFile: imageUrl.path())
        }
    }
    
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let lastValue = indexPath.section + 1 < sectionIndices.count ? sectionIndices[indexPath.section + 1] : messages.count
        if indexPath.row + 1 >= lastValue - sectionIndices[indexPath.section] {
            return isFromCurrentSender(message: message) ? .bubbleTail(.bottomRight, .curved) : .bubbleTail(.bottomLeft, .curved)
        }
        
        let futureMessage = messages[sectionIndices[indexPath.section] + indexPath.row + 1]
        return isFromCurrentSender(message: message) ? (isFromCurrentSender(message: futureMessage) ? .bubble : .bubbleTail(.bottomRight, .curved)) : (isFromCurrentSender(message: futureMessage) ? .bubbleTail(.bottomLeft, .curved) : .bubble)
    }
    
    func messageTimestampLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        let timestamp = dateFormatter.string(from: message.sentDate)
        return NSAttributedString(string: timestamp, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10.0)])
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        // Check if this message is the first in its section
        if indexPath.row == 0 {
            let sentDateString = MessageKitDateFormatter.shared.string(from: message.sentDate)
            return NSAttributedString(string: sentDateString, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10.0)])
        }
        return nil
    }
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return indexPath.row == 0 ? 25.0 : 0.0
    }
    
    func getReplyText(message: Message) -> NSAttributedString? {
        if let replyID = message.replyTo {
            let relevantMessage = messages.first(where: { $0.messageId == replyID })!
            
            var replyText = ""
            if threadAggregator.threadUsers.me.senderId == message.sender.senderId {
                if threadAggregator.threadUsers.me.senderId == relevantMessage.sender.senderId {
                    replyText = "You replied to yourself:\n"
                } else {
                    replyText = "You replied:\n"
                }
            } else {
                if threadAggregator.threadUsers.me.senderId == relevantMessage.sender.senderId {
                    replyText = "\(threadAggregator.threadUsers.them.displayName) replied to you:\n"
                } else {
                    replyText = "\(threadAggregator.threadUsers.them.displayName) replied to themself:\n"
                }
            }
            
            var text = ""
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = message.sender.senderId == currentSender.senderId ? .right : .left
            let replyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.secondaryLabel,
                .paragraphStyle: paragraphStyle
            ]
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.label,
                .paragraphStyle: paragraphStyle
            ]
            
            let attributedString = NSMutableAttributedString()
            var attachmentString = NSAttributedString()
            
            let label = UILabel()
            label.numberOfLines = 0 // This allows the label to display multiple lines of text
            
            let kindEnum = relevantMessage.kindEnum()
            if kindEnum == .photo || kindEnum == .video {
                let attachment = NSTextAttachment()
                var image: UIImage?
                if relevantMessage.kindEnum() == .photo {
                    text += "Photo Message\n"
                    if let mediaURL = relevantMessage.getMedia()?.url {
                        image = UIImage(contentsOfFile: mediaURL.path())
                    }
                } else if relevantMessage.kindEnum() == .video {
                    text += "Video Message\n"
                    image = relevantMessage.getMedia()!.image
                }
                attachment.image = image
                
                if let image = image {
                    let maxWidth = UIScreen.main.bounds.width * 0.75
                    let maxHeight: CGFloat = 80
                    
                    var imageSize = CGSize(width: image.size.width, height: image.size.height)
                    
                    // Check if the image width is greater than the max width
                    if imageSize.width > maxWidth {
                        let ratio = maxWidth / imageSize.width
                        imageSize = CGSize(width: maxWidth, height: imageSize.height * ratio)
                    }
                    
                    // Check if the image height is greater than the max height
                    if imageSize.height > maxHeight {
                        let ratio = maxHeight / imageSize.height
                        imageSize = CGSize(width: imageSize.width * ratio, height: maxHeight)
                    }
                    
                    let xOffset = (maxWidth - imageSize.width) / 2
                    let yOffset = (maxHeight - imageSize.height) / 2
                    
                    attachment.bounds = CGRect(x: xOffset, y: yOffset, width: imageSize.width, height: imageSize.height)
                    
                    attachmentString = NSAttributedString(attachment: attachment)
                }
            } else {
                text += relevantMessage.setData
            }
            
            if relevantMessage.setData == "" {
                attributedString.append(NSAttributedString(string: replyText, attributes: replyAttributes))
                let messageDeletedText = NSMutableAttributedString(string: "Message has been deleted", attributes: [
                    .font: UIFont.italicSystemFont(ofSize: 10.0),
                    .foregroundColor: UIColor.label ])
                attributedString.append(messageDeletedText)
            } else {
                attributedString.append(NSAttributedString(string: replyText, attributes: replyAttributes))
                attributedString.append(NSAttributedString(string: text, attributes: attributes))
                attributedString.append(attachmentString)
            }
            
            label.attributedText = attributedString
            
            return attributedString
        }
        return nil
    }
    
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        guard let message = message as? Message else { return nil }
        return getReplyText(message: message)
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        guard let message = message as? Message else { return 0 }
        if let attributedText = getReplyText(message: message) {
            let labelWidth: CGFloat = UIScreen.main.bounds.width * 0.75
            let boundingSize = CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude)
            let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
            let boundingRect = attributedText.boundingRect(with: boundingSize, options: options, context: nil)
            let labelHeight = ceil(boundingRect.size.height)
            return labelHeight + 10
        }
        return 0
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if let uploadingMessage = uploadQueue.uploading {
            var futureIndex = IndexPath(row: indexPath.row + 1, section: indexPath.section)
            let lastValue = indexPath.section + 1 < sectionIndices.count ? sectionIndices[indexPath.section + 1] : messages.count
            if futureIndex.row >= lastValue - sectionIndices[indexPath.section] {
                futureIndex = IndexPath(row: 0, section: indexPath.section + 1)
            }
            
            if futureIndex.section > sectionIndices.count - 1 { return nil }
            
            let flattenedIndex = sectionIndices[futureIndex.section] + futureIndex.row
            let futureMessage = messages[flattenedIndex]
            
            if futureMessage.messageId == uploadingMessage.messageId {
                return deliveredText
            }
        } else {
            let myLastMessage = messages.last(where: { $0.sender.senderId == threadAggregator.threadUsers.me.senderId })
            if myLastMessage?.messageId == message.messageId {
                return deliveredText
            }
        }
        return nil
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if let uploadingMessage = uploadQueue.uploading {
            var futureIndex = IndexPath(row: indexPath.row + 1, section: indexPath.section)
            let lastValue = indexPath.section + 1 < sectionIndices.count ? sectionIndices[indexPath.section + 1] : messages.count
            if futureIndex.row >= lastValue - sectionIndices[indexPath.section] {
                futureIndex = IndexPath(row: 0, section: indexPath.section + 1)
            }
            
            if futureIndex.section > sectionIndices.count - 1 { return 0 }
            
            let flattenedIndex = sectionIndices[futureIndex.section] + futureIndex.row
            let futureMessage = messages[flattenedIndex]
            
            if futureMessage.messageId == uploadingMessage.messageId {
                return 15
            }
        } else {
            let myLastMessage = messages.last(where: { $0.sender.senderId == threadAggregator.threadUsers.me.senderId })
            if myLastMessage?.messageId == message.messageId {
                return 15
            }
        }
        return 0
    }
    
    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        let lastValue = indexPath.section + 1 < sectionIndices.count ? sectionIndices[indexPath.section + 1] : messages.count
        return indexPath.section == (sectionIndices.count - 1) && indexPath.row == (lastValue - sectionIndices[indexPath.section] - 1) ? 10.0 : 0
    }
    
    func replyViewDidDelete(_ replyView: ReplyView) {
        replyView.isHidden = true
        replyView.msgLabel.text = ""
        replyView.imageView.image = nil
        replyView.imageView.isHidden = false
        messageInputBar.topStackView.layoutIfNeeded()
        messageInputBar.invalidateIntrinsicContentSize()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let flattenedIndex = sectionIndices[indexPath.section] + indexPath.row
        let message = messages[flattenedIndex]
        
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [self] _ in
            let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { _ in
                // Handle copy action
                switch message.kind {
                case .text(let text), .emoji(let text):
                    UIPasteboard.general.string = text
                    break
                case .linkPreview(let link):
                    UIPasteboard.general.string = link.url.absoluteString
                    break
                case .photo(let media):
                    UIPasteboard.general.image = UIImage(contentsOfFile: media.url?.path() ?? "") ?? UIImage()
                case .video(let media):
                    guard let videoURL = media.url else { return }
                    
                    do {
                        let videoData = try Data(contentsOf: videoURL)
                        UIPasteboard.general.setData(videoData, forPasteboardType: kUTTypeVideo as String)
                    } catch {
                        print("Error: failure to read video file: \(error)")
                    }
                    break
                default:
                    break
                }
            }
            
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [self] _ in
                // Handle delete action
                alert(title: "Confirm", message: "Are you sure you would like to delete this message?", actions: [("Yes", (UIAlertAction.Style.destructive, {
                    ref.child("Threads").child(self.threadAggregator.selectedThread).child("deleted").observeSingleEvent(of: .value) { [self] snapshot in
                        var stringArray = snapshot.value as? [String] ?? []
                        if !stringArray.contains(message.messageId) {
                            stringArray.append(message.messageId)
                            ref.child("Threads").child(threadAggregator.selectedThread).child("deleted").setValue(stringArray)
                        }
                    }
                    ref.child("Threads").child(self.threadAggregator.selectedThread).child("messages").child(message.messageId).child("d").setValue("")
                })), ("No", (UIAlertAction.Style.default, {}))])
            }
            
            let reply = UIAction(title: "Reply", image: UIImage(systemName: "arrowshape.turn.up.right")) { [self] _ in
                // Handle reply action
                replyView.isHidden = false
                messageInputBar.topStackView.layoutIfNeeded()
                
                replyView.setMessage(message: message, threadUsers: threadAggregator.threadUsers)
                
                messageInputBar.inputTextView.becomeFirstResponder()
                messagesCollectionView.scrollToLastItem(animated: true)
            }
            
            let save = UIAction(title: "Save", image: UIImage(systemName: "square.and.arrow.down")) { [self] _ in
                // Handle save action
                switch message.kind {
                case .video(let media):
                    UISaveVideoAtPathToSavedPhotosAlbum(media.url?.path() ?? "", self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
                    break
                case .photo(let media):
                    UIImageWriteToSavedPhotosAlbum(media.image ?? UIImage(), self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
                    break
                default:
                    break
                }
            }
            
            let share = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) {  [self] _ in
                // Handle share action
                var itemToShare: Any?
                
                switch message.kind {
                case .photo(let media):
                    itemToShare = media.image
                    break
                case .video(let media):
                    itemToShare = media.url
                    break
                case .text(let text), .emoji(let text):
                    itemToShare = text
                    break
                case .linkPreview(let link):
                    itemToShare = link.url
                    break
                default:
                    break
                }
                
                if let itemToShare = itemToShare {
                    // set up activity view controller
                    let activityViewController = UIActivityViewController(activityItems: [itemToShare], applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = view // so that iPads won't crash
                    
                    // present the view controller
                    present(activityViewController, animated: true, completion: nil)
                }
            }
            
            var menuChildren = [copy, reply, share]
            
            if message.kindEnum() == .photo || message.kindEnum() == .video {
                menuChildren.insert(save, at: 0)
            }
            
            if message.sender.senderId == threadAggregator.threadUsers.me.senderId {
                menuChildren.append(delete)
            }
            
            return UIMenu(title: "", children: menuChildren)
        }
        
        return config
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            impact(style: .error)
            alert(title: "Error", message: "Unable to save image: \(error)", actionTitle: "Okay")
        } else {
            impact(style: .success)
            alert(title: "Success", message: "Image saved successfully", actionTitle: "Okay")
        }
    }
    
    @objc func video(_ videoPath: String, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            impact(style: .error)
            alert(title: "Error", message: "Unable to save video: \(error)", actionTitle: "Okay")
        } else {
            impact(style: .success)
            alert(title: "Success", message: "Video saved successfully", actionTitle: "Okay")
        }
    }
}


extension ChatViewController: InputBarAccessoryViewDelegate, AttachmentManagerDelegate, UITextInputTraits {
    
    func attachmentManager(_ manager: AttachmentManager, shouldBecomeVisible: Bool) {
        setAttachmentManager(active: shouldBecomeVisible)
    }
    
    func attachmentManager(_ manager: AttachmentManager, didReloadTo attachments: [AttachmentManager.Attachment]) {
        messageInputBar.sendButton.isEnabled = manager.attachments.count > 0
    }
    
    func attachmentManager(_ manager: AttachmentManager, didInsert attachment: AttachmentManager.Attachment, at index: Int) {
        messageInputBar.sendButton.isEnabled = manager.attachments.count > 0
    }
    
    func attachmentManager(_ manager: AttachmentManager, didRemove attachment: AttachmentManager.Attachment, at index: Int) {
        messageInputBar.sendButton.isEnabled = manager.attachments.count > 0
        if manager.attachments.isEmpty { messageInputBar.invalidatePlugins() }
    }
    
    func attachmentManager(_ manager: AttachmentManager, didSelectAddAttachmentAt index: Int) {
        presentInputActionSheet()
    }
    
    func setAttachmentManager(active: Bool) {
        let topStackView = messageInputBar.topStackView
        if active && !topStackView.arrangedSubviews.contains(attachmentManager.attachmentView) {
            topStackView.insertArrangedSubview(attachmentManager.attachmentView, at: topStackView.arrangedSubviews.count)
            topStackView.layoutIfNeeded()
        } else if !active && topStackView.arrangedSubviews.contains(attachmentManager.attachmentView) {
            topStackView.removeArrangedSubview(attachmentManager.attachmentView)
            topStackView.layoutIfNeeded()
        }
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        var rid:String? = replyView.isHidden ? nil : replyView.getMessage().messageId
        
        for attachment in attachmentManager.attachments {
            switch attachment {
            case .image(let image):
                saveImageAndUpload(image: image, rid: rid)
                rid = nil
                break
            case .url(let url):
                // url for video
                saveVideoAndUpload(videoURL: url, rid: rid)
                rid = nil
            default:
                break
            }
        }
        
        replyView.deleteMessage()
        
        if text != "" {
            let nowDate = Date()
            var kind = MessageKind.text(text)
            
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
            let range = NSRange(trimmedText.startIndex..<trimmedText.endIndex, in: trimmedText)
            
            if let match = detector.firstMatch(in: text, options: [], range: range),
               match.range == range {
                if match.resultType == .link {
                    kind = .linkPreview(Link(text: match.url?.absoluteString, url: match.url!, teaser: "", thumbnailImage: UIImage()))
                } else if match.resultType == .phoneNumber {
                    kind = .linkPreview(Link(url: URL(string: "tel:\(match.phoneNumber!.filter("0123456789".contains))")!, title: match.phoneNumber, teaser: "Tap To Call", thumbnailImage: UIImage(systemName: "phone.fill")!))
                }
            } else if text.unicodeScalars.count == 1 && text.unicodeScalars.first?.properties.isEmoji == true {
                // is an emoji
                kind = .emoji(text)
            }
            
            let message = Message(sender: threadAggregator.threadUsers.me, messageId: "\(nowDate.betterDate())-\(UUID().uuidString)", sentDate: nowDate, kind: kind, replyTo: rid)
            
            addToUploadQueue(message: message)
        }
        
        inputBar.inputTextView.text = ""
        messageInputBar.invalidatePlugins()
        messagesCollectionView.scrollToLastItem(animated: true)
    }
    
    func didSelectURL(_ url: URL) {
        UIApplication.shared.open(url)
    }
    
    func didSelectDate(_ date: Date) {
        // there is a weird 31 year delta where 1970 = 2001, so I have to subtract 31 years from epoch
        // It seems like apple's calendar epoch time started in January 1, 2001
        let newTime = date.timeIntervalSince1970 - 978307200
        if let url = URL(string: "calshow:\(newTime)") {
            UIApplication.shared.open(url)
        }
    }
    
    func didSelectAddress(_ addressComponents: [String : String]) {
        let stringURL = "http://maps.apple.com/?address=\(addressComponents)"
        if let url = URL(string: stringURL) {
            UIApplication.shared.open(url)
        }
    }
    
    func didSelectPhoneNumber(_ phoneNumber: String) {
        let stringURL = "tel:\(phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: ""))"
        if let url = URL(string: stringURL) {
            UIApplication.shared.open(url)
        }
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key : Any] {
        var attributes = MessageLabel.defaultAttributes as [NSMutableAttributedString.Key : Any]
        attributes[.foregroundColor] = UIColor.link
        attributes[.underlineColor] = UIColor.link
        
        return attributes
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .phoneNumber, .date, .address]
    }
    
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        let canPasteVideo = UIPasteboard.general.contains(pasteboardTypes: [kUTTypeMovie as String], inItemSet: nil)
        return action == #selector(paste(_:)) || (action == #selector(paste(_:)) && canPasteVideo)
    }
    
    override func paste(_ sender: Any?) {
        if let videoData = UIPasteboard.general.data(forPasteboardType: kUTTypeMovie as String) {
            pasteMedia(data: videoData, tag: "mov")
        } else {
            super.paste(sender)
        }
    }
    
    func pasteMedia(data: Data, tag: String) {
        let fileManager = FileManager.default
        let tempDirectory = NSTemporaryDirectory()
        let tempFilePath = tempDirectory + "temp_file." + tag
        fileManager.createFile(atPath: tempFilePath, contents: data, attributes: nil)
        let _ = self.attachmentManager.handleInput(of: URL(fileURLWithPath: tempFilePath) as AnyObject)
    }
    
}

extension ChatViewController: MessageCellDelegate {
    
    func didTapMessageTopLabel(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let flattenedIndex = sectionIndices[indexPath.section] + indexPath.row
        let message = messages[flattenedIndex]
        if let rid = message.replyTo {
            let relevantIndex = messages.firstIndex(where: { $0.messageId == rid })
            let distance = messages.distance(from: messages.startIndex, to: relevantIndex!)
            var indexOfMessage = IndexPath(row: 0, section: 0)
            
            for (i, section) in sectionIndices.enumerated() {
                if distance - section < 0 {
                    indexOfMessage = IndexPath(row: distance - sectionIndices[i - 1], section: i - 1)
                    break
                }
            }
            
            if distance - sectionIndices.last! >= 0 {
                indexOfMessage = IndexPath(row: distance - sectionIndices.last!, section: sectionIndices.count - 1)
            }
            
            messagesCollectionView.scrollToItem(at: indexOfMessage, at: .bottom, animated: true)
        }
    }
    
    func didTapBackground(in cell: MessageKit.MessageCollectionViewCell) {
        view.endEditing(true)
    }
    
    func didTapMessage(in cell: MessageKit.MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let flattenedIndex = sectionIndices[indexPath.section] + indexPath.row
        let message = messages[flattenedIndex]
        switch message.kind {
        case .linkPreview(let link):
            UIApplication.shared.open(link.url)
            break
        default:
            break
        }
    }
    
    func didTapImage(in cell: MessageKit.MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        
        let flattenedIndex = sectionIndices[indexPath.section] + indexPath.row
        let message = messages[flattenedIndex]
        
        switch message.kind {
        case .photo(let media):
            if let url = media.url {
                let vc = PhotoViewerViewController(with: url)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            break
        case .video(let media):
            if let url = media.url {
                do {
                    play(withData: try Data(contentsOf: url), name: message.setData)
                } catch {
                    print("Error: Could not play video")
                }
            }
        default:
            break
        }
    }
    
}


extension Array where Element == Message {
    mutating func replaceElement(with message: Message) {
        if let firstIndex = self.firstIndex(where: { $0.messageId == message.messageId }) {
            self[firstIndex] = message
        } else {
            self.append(message)
            self.sort(by: { $0.sentDate < $1.sentDate })
        }
    }
}



open class ReplyView: UIView {
    
    private var message: Message!
    
    var replyToLabel: UILabel = {
        let replyToLabel = UILabel()
        replyToLabel.font = UIFont.systemFont(ofSize: 8)
        replyToLabel.textColor = .tertiaryLabel
        return replyToLabel
    }()
    
    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.addTarget(self, action: #selector(deleteMessage), for: .touchUpInside)
        return button
    }()
    
    lazy var msgLabel: UILabel = {
        let msgLabel = UILabel()
        msgLabel.font = UIFont.systemFont(ofSize: 12)
        msgLabel.numberOfLines = 0
        msgLabel.textColor = .secondaryLabel
        return msgLabel
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 10
        imageView.backgroundColor = .tertiarySystemBackground
        imageView.clipsToBounds = true
        return imageView
    }()
    
    lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 8
        stack.clipsToBounds = true
        return stack
    }()
    
    weak var delegate: ReplyViewDelegate?
    
    var intrinsicContentHeight: CGFloat = 66 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    open override var intrinsicContentSize: CGSize {
        return CGSize(width: 0, height: intrinsicContentHeight)
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setup()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        backgroundColor = .secondarySystemBackground
        setupSubviews()
        setupConstraints()
    }
    
    private func setupSubviews() {
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(msgLabel)
        stackView.addArrangedSubview(closeButton)
        addSubview(stackView)
        
        addSubview(replyToLabel)
        
        replyToLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        msgLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 66),
            replyToLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            replyToLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            replyToLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            closeButton.widthAnchor.constraint(equalToConstant: 20),
            closeButton.heightAnchor.constraint(equalToConstant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 40),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }
    
    
    func setMessage(message: Message, threadUsers: ThreadUsers) {
        self.message = message
        msgLabel.font = UIFont.systemFont(ofSize: 12)
        if message.setData == "" {
            msgLabel.text = "Message Deleted"
            msgLabel.font = UIFont.italicSystemFont(ofSize: 12)
            imageView.isHidden = true
        } else {
            if let media = message.getMedia() {
                imageView.isHidden = false
                if message.kindEnum() == .photo {
                    imageView.image = UIImage(contentsOfFile: media.url!.path())
                    msgLabel.text = "Image File"
                } else if message.kindEnum() == .video {
                    imageView.image = media.image
                    msgLabel.text = "Video File"
                }
            } else {
                msgLabel.text = message.setData
                imageView.isHidden = true
            }
        }
        if message.sender.senderId == threadUsers.me.senderId {
            replyToLabel.text = "Replying to yourself:"
        } else {
            replyToLabel.text = "Replying to \(threadUsers.them.displayName):"
        }
    }
    
    func getMessage() -> Message {
        return message
    }
    
    @objc func deleteMessage() {
        delegate?.replyViewDidDelete(self)
    }
    
}


protocol ReplyViewDelegate: AnyObject {
    func replyViewDidDelete(_ replyView: ReplyView)
}




class WaveFormView: UIView {
    
    lazy var timeLabel: UILabel = {
        let label = UILabel()
        self.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 10)
        ])
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpView()
    }
    
    
    func setUpView() {
        layer.cornerRadius = frame.height / 2
        timeLabel.text = "hello!"
    }
    
    
}
