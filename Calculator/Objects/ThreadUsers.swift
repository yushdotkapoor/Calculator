//
//  ThreadUsers.swift
//  Calculator
//
//  Created by Yush Raj Kapoor on 3/25/23.
//

import Foundation
import MessageKit


struct ThreadUsers {
    var me: User
    var them: User
    
    func getUser(byID userID: String) -> User {
        return me.senderId == userID ? me : them
    }
}
