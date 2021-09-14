//
//  Notifications.swift
//  Calculator
//
//  Created by florian in 2019.
//

import UIKit

class PushNotificationSender {
    func sendPushNotification(to token: String, title: String, body: String) {
        
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["to" : token,
                                           "notification" : ["title" : title, "body" : body, "badge":1, "sound":"default"],
                                           "data" : ["user" : "test_id"]
        ]
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        //request.setValue(INSERT SERVER KEY HERE, forHTTPHeaderField: "Authorization") DELETE LINE UNDER THIS ONE
        request.setValue(Credentials().notification_service_key, forHTTPHeaderField: "Authorization")
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        //NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
                 
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()
    }
}
