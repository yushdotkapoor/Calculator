//
//  ThreadAggregator.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/23/23.
//

import Foundation
import UIKit
import MessageKit
import Firebase


class ThreadAggregator {
    var selectedThread:String!
    var threadUsers:ThreadUsers!
    
    init(selectedThread: String, threadUsers:ThreadUsers) {
        self.selectedThread = selectedThread
        self.threadUsers = threadUsers
    }
    
    private func incrementThread() {
        let threadTag = UserDefaults.standard.integer(forKey: selectedThread)
        let rand = Int.random(in: 0...1)
        UserDefaults.standard.setValue(threadTag + [-1, 1][rand], forKey: selectedThread)
    }
    
    func listen() {
        let decodedMessages = decodeMessageFile()
        var decodedMsgs = Message.getMessages(fromDictionary: decodedMessages as NSDictionary, threadUsers: threadUsers)
        decodedMsgs.sort(by: { $0.sentDate < $1.sentDate })
        var timeFrom = "0"
        if let lastMsg = decodedMsgs.last(where: { $0.sender.senderId != myKey }) {
            timeFrom = String(lastMsg.sentDate.betterDate())
        }
        ref.child("Threads").child(selectedThread).child("deleted").observe(.value) { [self] snapshot in
            var decodedMs = decodeMessageFile()
            var toDelete: [String] = []
            if let stringArray = snapshot.value as? [String] {
                for messageID in stringArray {
                    if decodedMs.keys.contains(messageID) {
                        if decodedMs[messageID]!["d"] != "" {
                            toDelete.append(messageID)
                        }
                        decodedMs[messageID]!["d"] = ""
                    }
                }
                cacheMessages(json: try! JSONEncoder().encode(decodedMs))
                UserDefaults.standard.set(toDelete, forKey: "\(selectedThread!)_delete")
                incrementThread()
            }
        }
        
        ref.child("Threads").child(selectedThread).child("messages").queryOrderedByKey().queryStarting(atValue: timeFrom).observe(.value) { [self] (snapshot) in
            let msgsDict = NSMutableDictionary(dictionary: decodeMessages(snapshot: snapshot, threadUsers: threadUsers))
            msgsDict.addEntries(from: decodeMessageFile())
            cacheMessages(json: try! JSONEncoder().encode(msgsDict as? [String: [String: String]]))
            incrementThread()
            
            if let vc = getTopViewController() as? ChatViewController {
                if vc.threadAggregator.selectedThread == selectedThread {
                    ref.child("Users").child(threadUsers.me.senderId).child("threads").child(selectedThread).child("uids").child(threadUsers.me.senderId).setValue(false)
                }
            }
        }
    }
    
    private func decodeMessages(snapshot: DataSnapshot, threadUsers: ThreadUsers) -> [String: [String: String]] {
        var decoded:[String: [String: String]] = [:]
        for msg in snapshot.value as? [String: [String: String]] ?? [:] {
            let messageId = msg.key
            let sentDate = Date(timeIntervalSince1970: Double(msg.value["sd"]!)! / 1000)
            let msgData = msg.value["d"]!
            let senderID = msg.value["sid"]!
            
            let id1 = senderID
            let id2 = threadUsers.me.senderId != senderID ? threadUsers.me : threadUsers.them
            
            let unOb = 🤣(🌩: msgData, 🐔: id1, 🐚: id2.senderId, 🐉: sentDate, 🐳: messageId)
            
            var decodedMessage = msg.value
            decodedMessage["d"] = unOb
            decoded[messageId] = decodedMessage
        }
        return decoded
    }
    
    
    func decodeMessageFile() -> [String: [String: String]] {
        if let fileUrl = getFileURL(for: "messages_\(selectedThread!).json") {
            let d = (try? Data(contentsOf: fileUrl)) ?? Data()
            let decoded = try! JSONDecoder().decode([String: [String: String]].self, from: d)
            return decoded
        }
        return [:]
    }
    
    
    private func cacheMessages(json: Data) {
        let pathDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? FileManager().createDirectory(at: pathDirectory, withIntermediateDirectories: true)
        let filePath = pathDirectory.appendingPathComponent("messages_\(selectedThread!).json")
        
        do {
            try json.write(to: filePath)
        } catch {
            print("Failed to write JSON data: \(error.localizedDescription)")
        }
    }
}

