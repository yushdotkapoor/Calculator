//
//  StorageManager.swift
//  Messenger
//
//  Created by Yush Raj Kapoor on 3/20/23
//

import Foundation
import Firebase
import UIKit

/// Allows you to get, fetch, and upload files to firebase  storage
final class StorageManager {
    
    static let shared = StorageManager()
    
    private init() {}
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    public typealias DownloadCompletion = (Result<Message, Error>) -> Void
    
    
    /// Upload image that will be sent in a conversation message
    public func uploadData(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("message_files/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                // failed
                print("failed to upload data to firebase")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_files/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child("message_files/" + path)
        
        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            
            completion(.success(url))
        })
    }
    
    func downloadMedia(fileName: String, message: Message, threadUsers: ThreadUsers, completion: @escaping StorageManager.DownloadCompletion) {
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
        
        StorageManager.shared.downloadURL(for: fileName) { result in
            switch result {
            case .failure(let error):
                print(error)
                completion(.failure(error))
                return
            case .success(let url):
                print("download url \(url)")
                
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
                        currentlyDownloading.removeAll(where: { $0 == message.messageId })
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
                        currentlyDownloading.removeAll(where: { $0 == message.messageId })
                        completion(.failure(error))
                        return
                    }
                }
            }
        }
    }
}
