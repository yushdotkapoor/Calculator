//
//  Link.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/25/23.
//

import Foundation
import MessageKit
import UIKit
import LinkPresentation
import MobileCoreServices

struct Link: LinkItem {
    var text: String?
    var attributedText: NSAttributedString?
    var url: URL
    var realURL: String
    var title: String?
    var teaser: String
    var thumbnailImage: UIImage
    
    init(text: String? = nil, attributedText: NSAttributedString? = nil, url: URL, title: String? = nil, teaser: String, thumbnailImage: UIImage) {
        self.text = text == nil ? url.absoluteString : text!
        self.attributedText = attributedText
        self.url = url
        self.realURL = url.absoluteString
        self.title = title
        self.teaser = teaser
        self.thumbnailImage = thumbnailImage
    }
    
    mutating func setURL(string: String) {
        if let newURL = URL(string: realURL) {
            self.url = newURL
        }
        self.realURL = string
    }
    
    func getURL() -> String {
        return realURL
    }
    
    func getAttributes(mid: String, completion: @escaping (Link) -> Void) {
        var link = self
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent("link_\(mid).jpg")
        
        if let phoneNumber = extractPhoneNumber(from: url.absoluteString) {
            link.url = URL(string: "tel:\(phoneNumber)")!
            link.title = phoneNumber
            link.teaser = "Tap To Call"
            link.thumbnailImage = UIImage(systemName: "phone.fill")!
            currentlyDownloading.removeAll(where: { $0 == mid })
            completion(link)
        } else if FileManager.default.fileExists(atPath: fileURL.path()), let image = UIImage(contentsOfFile: fileURL.path()), let teaser = UserDefaults.standard.string(forKey: "link_teaser\(mid)"), let title = UserDefaults.standard.string(forKey: "link_title\(mid)") {
            link.thumbnailImage = image
            link.teaser = teaser
            link.title = title
            currentlyDownloading.removeAll(where: { $0 == mid })
            completion(link)
        } else {
            fetchLinkMetadata(from: url) { metadata, error in
                if let error = error {
                    print("Error fetching metadata: \(error.localizedDescription)")
                    currentlyDownloading.removeAll(where: { $0 == mid })
                } else if let metadata = metadata {
                    UserDefaults.standard.setValue(metadata.title, forKey: "link_title\(mid)")
                    link.text = metadata.title
                    if let imageProvider = metadata.imageProvider {
                        imageProvider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { data, error in
                            if let error = error {
                                print("Error loading image: \(error.localizedDescription)")
                            } else if let data = data as? Data, let image = UIImage(data: data) {
                                
                                do {
                                    try data.write(to: fileURL)
                                } catch {
                                    print("Error writing image data to file: \(error)")
                                }
                                
                                // Use the loaded image
                                link.thumbnailImage = image
                                fetchTeaser(from: metadata.originalURL) { teaser in
                                    if let teaser = teaser {
                                        UserDefaults.standard.setValue(teaser, forKey: "link_teaser\(mid)")
                                        link.teaser = teaser
                                    }
                                    currentlyDownloading.removeAll(where: { $0 == mid })
                                    completion(link)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func fetchLinkMetadata(from url: URL, completion: @escaping (LPLinkMetadata?, Error?) -> Void) {
        let metadataProvider = LPMetadataProvider()
        metadataProvider.startFetchingMetadata(for: url) { metadata, error in
            completion(metadata, error)
        }
    }
    
    func fetchTeaser(from url: URL?, completion: @escaping (String?) -> Void) {
        guard let url = url else {
            completion(nil)
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }
            
            let pattern = "<meta property=\"og:description\" content=\"(.*?)\""
            let regex = try! NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            if let match = regex.firstMatch(in: html, options: [], range: range),
               let teaserRange = Range(match.range(at: 1), in: html) {
                let teaser = html[teaserRange].trimmingCharacters(in: .whitespacesAndNewlines)
                    completion(teaser)
            } else {
                completion(nil)
            }
        }
        task.resume()
    }
    
    func extractPhoneNumber(from string: String) -> String? {
        var phoneNumber: String?
        if string.hasPrefix("tel:") {
            phoneNumber = string.dropFirst(4).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
            let matches = detector?.matches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
            phoneNumber = matches?.first.flatMap { (string as NSString).substring(with: $0.range) }
        }
        return phoneNumber
    }
    
}
