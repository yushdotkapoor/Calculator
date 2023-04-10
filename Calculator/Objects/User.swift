//
//  User.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/25/23.
//

import Foundation
import MessageKit


struct User: SenderType, Codable {
    var notifyWithSender: String?
    var notifyWithBody: String?
    var senderId: String
    var displayName: String
    var token: String?
}
