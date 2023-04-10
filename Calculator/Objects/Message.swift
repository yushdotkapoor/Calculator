//
//  Message.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/25/23.
//

import Foundation
import MessageKit
import UIKit



struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    var replyTo: String?
    
    enum KindEnum {
        case text
        case attributedText
        case photo
        case video
        case location
        case emoji
        case audio
        case contact
        case linkPreview
        case custom
    }
    
    
    init(sender: SenderType, messageId: String? = nil, sentDate: Date, kind: MessageKind, replyTo: String? = nil) {
        let msgID = messageId != nil ? messageId : "\(sentDate.betterDate())-\(UUID().uuidString)"
        self.sender = sender
        self.messageId = msgID!
        self.sentDate = sentDate
        self.kind = kind
        self.replyTo = replyTo
    }
    
    var setData: String {
        get {
            switch kind {
            case .text(let string), .emoji(let string):
                return string
            case .photo(let mediaItem), .video(let mediaItem):
                guard let mediaItem = mediaItem as? Media else { break }
                return mediaItem.fileName ?? ""
            case .linkPreview(let linkItem):
                guard let linkItem = linkItem as? Link else { break }
                return linkItem.getURL()
            default:
                break
            }
            return ""
        }
        set {
            switch kind {
            case .text(_):
                kind = MessageKind.text(newValue)
                break
            case .emoji(_):
                kind = MessageKind.emoji(newValue)
                break
            case .photo(let mediaItem):
                guard var mediaItem = mediaItem as? Media else { break }
                mediaItem.fileName = newValue
                kind = .photo(mediaItem)
                break
            case .video(let mediaItem):
                guard var mediaItem = mediaItem as? Media else { break }
                mediaItem.fileName = newValue
                kind = .video(mediaItem)
                break
            case .linkPreview(let linkItem):
                guard var linkItem = linkItem as? Link else { break }
                linkItem.setURL(string: newValue)
                kind = .linkPreview(linkItem)
                break
            default:
                break
            }
        }
    }
    
    static func getMessages(fromDictionary msgArr: NSDictionary?, threadUsers: ThreadUsers) -> [Message] {
        guard let msgArr = msgArr else { return [] }
        var messages:[Message] = []
        for msg in msgArr {
            guard let msgID = msg.key as? String, let msg = msg.value as? [String:String] else { return messages }
            let type = msg["t"]!
            let msgData = msg["d"]!
            let senderID = msg["sid"]!
            let replyTo = msg["rid"]
            let formattedDate = Date(timeIntervalSince1970: (Double(msg["sd"]!) ?? 0) / 1000)
            
            var k = MessageKind.text("")
            switch type {
            case "text":
                k = MessageKind.text(msgData)
                break
            case "emoji":
                k = MessageKind.emoji(msgData)
                break
            case "photo":
                k = MessageKind.photo(Media(fileName: msgData))
                break
            case "video":
                k = MessageKind.video(Media(fileName: msgData))
                break
            case "linkPreview":
                k = MessageKind.linkPreview(Link(url: URL(string: msgData)!, teaser: "", thumbnailImage: UIImage()))
                break
            default:
                break
            }
            
            messages.append(Message(sender: threadUsers.getUser(byID: senderID), messageId: msgID, sentDate: formattedDate, kind: k, replyTo: replyTo))
        }
        messages.sort(by: { $0.sentDate < $1.sentDate })
        return messages
    }
    
    func performPushModulations(threadUsers: ThreadUsers) -> Message {
        var msg = self
        let dat = msg.setData
        let ob = 😂(🥮: dat, 🥛: threadUsers.me.senderId, 🎂: threadUsers.them.senderId, 🍟: sentDate, 🫐: messageId)
        msg.setData = ob
        
        return msg
    }
    
    func databaseWorthy() -> [String: Any] {
        var mess: [String: Any] = [
            "d": setData,
            "sid": sender.senderId,
            "t": kindString(),
            "sd": sentDate.betterDate(),
        ]
        if let rid = replyTo {
            mess["rid"] = rid
        }
        return mess
    }
    
    func kindString() -> String {
        var offset = 0
        var findParentheses = false
        let k = "\(kind)"
        
        while !findParentheses {
            if k.substring(with: offset..<(offset + 1)) == "(" {
                findParentheses = true
            }
            else {
                offset += 1
            }
        }
        
        let sub = k.prefix(offset)
        return String(sub)
    }
    
    func kindEnum() -> KindEnum{
        switch kind {
        case .video(_):
            return .video
        case .text(_):
            return .text
        case .attributedText(_):
            return .attributedText
        case .photo(_):
            return .photo
        case .location(_):
            return .location
        case .emoji(_):
            return .emoji
        case .audio(_):
            return .audio
        case .contact(_):
            return .contact
        case .linkPreview(_):
            return .linkPreview
        case .custom(_):
            return .custom
        }
    }
    
    func getMedia() -> Media? {
        switch kind {
        case .video(let media), .photo(let media):
            guard let media = media as? Media else { break }
            return media
        default:
            break
        }
        return nil
    }
    
    func getLink() -> Link? {
        switch kind {
        case .linkPreview(let link):
            guard let link = link as? Link else { break }
            return link
        default:
            break
        }
        return nil
    }
    
    func getVideoThumbnailURL(completion: ((URL) -> Void)? = nil) {
        let media = self.getMedia()
        if let existingURL = getFileURL(for: "thumb_" + (media?.fileName ?? "")) {
            completion?(existingURL)
            return
        }
        if self.kindEnum() == .video, let media = media  {
            generateThumbnailImage(fileName: media.fileName!) { thumbnailImage in
                do {
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let fileURL = documentsDirectory.appendingPathComponent("thumb_" + media.fileName!)
                    let thumbnailData = thumbnailImage?.jpegData(compressionQuality: 1.0)
                    try thumbnailData?.write(to: fileURL, options: .atomic)
                    print("\("thumb_" + media.fileName!) saved @ \(fileURL)")
                    completion?(fileURL)
                } catch {
                    print("Error: \(error)")
                }
            }
        }
    }
}
