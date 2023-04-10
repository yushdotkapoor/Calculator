//
//  CloudKit.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/30/23.
//

import Foundation
import CloudKit
import UIKit

class CloudStorage {
    static var shared = CloudStorage()
    
    
    public typealias UploadPictureCompletion = (Result<Void?, Error>) -> Void
    public typealias DownloadCompletion = (Result<Message, Error>) -> Void
    
    
    
    func uploadMedia(message: Message, threadUsers: ThreadUsers, completion: @escaping UploadPictureCompletion) {
        let media = message.getMedia()!
        let fileName = media.fileName!
        do {
            let fileData = try Data(contentsOf: media.url!)
            let dataString = fileData.base64EncodedString()
            
            let encoded_output = 😂(🥮: dataString, 🥛: threadUsers.me.senderId, 🎂: threadUsers.them.senderId, 🍟: message.sentDate, 🫐: message.messageId, ez: true, messageID: message.messageId)
            
            print("uploading \(fileName)")
            let mediaRecord = CKRecord(recordType: "Media", recordID: CKRecord.ID(recordName: fileName))
            mediaRecord["title"] = fileName
            
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
            let encodedData = encoded_output.data(using: .utf8)!
            try encodedData.write(to: tempURL, options: .atomic)
            
            let videoAsset = CKAsset(fileURL: tempURL)
            mediaRecord["media"] = videoAsset
            
            let op = CKModifyRecordsOperation(recordsToSave: [mediaRecord])
            op.perRecordProgressBlock =  { record, progress in
                DispatchQueue.main.async {
                    print("\(fileName) progress: \(progress)")
                    UserDefaults.standard.setValue((0.5 + (progress * 0.7)) * 0.9, forKey: "uploadProgress_\(message.messageId)")
                }
            }
            
            op.modifyRecordsResultBlock = { result in
                switch result {
                case .failure(let error):
                    print("ERROR: \(error) with uploading \(fileName)")
                    completion(.failure(error))
                    return
                case .success(_):
                    print("\(fileName) uploaded succesfully")
                    completion(.success(nil))
                    return
                }
            }
            CKContainer(identifier: Credentials().containerName()).publicCloudDatabase.add(op)
        } catch {
            print("Error saving video data to file: \(error.localizedDescription)")
        }
    }
    
    
    func downloadMedia(fileName: String, message: Message, threadUsers: ThreadUsers, completion: @escaping DownloadCompletion) {
        var message = message
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        var media = message.getMedia()!
        if FileManager.default.fileExists(atPath: fileURL.path()) {
            // already exists here
            media.url = fileURL
            if message.kindEnum() == .video {
                message.getVideoThumbnailURL() { thumbnailURL in
                    if let thumbnail = UIImage(contentsOfFile: thumbnailURL.path()) {
                        media.image = thumbnail
                        media.placeholderImage = thumbnail
                    }
                    message.kind = .video(media)
                    completion(.success(message))
                }
            } else {
                message.kind = .photo(media)
                completion(.success(message))
            }
            return
        }
        
        print("Downloading \(fileName)")
        let op = CKFetchRecordsOperation(recordIDs: [CKRecord.ID(recordName: fileName)])
        op.perRecordProgressBlock = { record, progress in
            DispatchQueue.main.async {
                print("\(record.recordName) progress: \(progress)")
                UserDefaults.standard.setValue((0.5 + (progress * 0.7)) * 0.9, forKey: "downloadProgress_\(message.messageId)")
            }
        }
        
        op.perRecordResultBlock = { recordID, result in
            switch result {
            case .failure(let error):
                print("Error Downloading Record  " + error.localizedDescription)
                completion(.failure(error))
                return
            case .success(let record):
                let mediaFile = record.object(forKey: "media") as! CKAsset
                let url = mediaFile.fileURL!
                
                DispatchQueue.global(qos: .utility).async {
                    do {
                        let data = try Data(contentsOf: url)
                        
                        let id1 = message.sender
                        let id2 = threadUsers.me.senderId != message.sender.senderId ? threadUsers.me : threadUsers.them
                        
                        let dat_de = 🤣(🌩: String(data: data, encoding: .utf8)!, 🐔: id1.senderId, 🐚: id2.senderId, 🐉: message.sentDate, 🐳: message.messageId, ez: true)
                        let de_data = Data(base64Encoded: dat_de)!
                        
                        if !FileManager.default.fileExists(atPath: fileURL.path()) {
                            try de_data.write(to: fileURL, options: .atomic)
                        }
                        print("\(fileName) saved @ \(fileURL)")
                        
                        media.url = fileURL
                        if message.kindEnum() == .video {
                            message.getVideoThumbnailURL() { thumbnailURL in
                                if let thumbnail = UIImage(contentsOfFile: thumbnailURL.path()) {
                                    media.image = thumbnail
                                    media.placeholderImage = thumbnail
                                }
                                message.kind = .video(media)
                                completion(.success(message))
                            }
                        } else {
                            message.kind = .photo(media)
                            completion(.success(message))
                        }
                        return
                    } catch {
                        print("Error when attempting to download data \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }
                }
            }
        }
        CKContainer(identifier: Credentials().containerName()).publicCloudDatabase.add(op)
    }
    
    
    
}
