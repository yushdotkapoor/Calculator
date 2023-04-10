//
//  Notifications.swift
//  Calculator
//
//  Created by florian in 2019.
//

import UIKit

class PushNotificationSender {
    static var shared = PushNotificationSender()
    
    func sendPushNotification(to token: String, title: String, body: String) {
        
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["to" : token,
                                           "notification" : ["title" : title == "" ? " " : title, "body" : body == "" ? " " : body, "badge":1, "sound":"default"],
                                           "data" : ["user" : "test_id"]
        ]
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        //request.setValue(INSERT SERVER KEY HERE, forHTTPHeaderField: "Authorization") DELETE LINE UNDER THIS ONE
        request.setValue(Credentials().notificationServiceKey(), forHTTPHeaderField: "Authorization")
        let task =  URLSession.shared.dataTask(with: request as URLRequest)
        task.resume()
    }
}
