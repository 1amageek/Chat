//
//  Message.swift
//  Chat
//
//  Created by 1amageek on 2017/02/01.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import Foundation

struct Message: Hashable {
    
    let id: String
    let createdAt: Date
    let text: String
    
    let recipient: User
    let sender: User
    
    var hashValue: Int {
        return self.id.hash
    }
    
    init(id: String, createdAt: Date, text: String, recipient: User, sender: User) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
        self.recipient = recipient
        self.sender = sender
    }
    
}

func == (lhs: Message, rhs: Message) -> Bool {
    return lhs.id == rhs.id
}

extension Message: JSONParsable {
    init(_ json: [AnyHashable : Any]) {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "eee MMM dd HH:mm:ss ZZZZ yyyy"
        let createdAtStr: String = json["created_at"] as! String
        let createdAt: Date = dateFormatter.date(from: createdAtStr)!
        let id: String = json["id_str"] as! String
        let text: String = json["text"] as! String
        
        let recipient: User = User(json["recipient"] as! [AnyHashable: Any])
        let sender: User = User(json["sender"] as! [AnyHashable: Any])
     
        self.id = id
        self.createdAt = createdAt
        self.text = text
        self.recipient = recipient
        self.sender = sender
        
    }
}
