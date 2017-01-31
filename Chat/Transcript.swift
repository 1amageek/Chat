//
//  Transcript.swift
//  Chat
//
//  Created by 1amageek on 2017/01/31.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import RealmSwift

class Transcript: Object {
    
    dynamic var id: String!
    
    /**
     - SeeAlso: Chat.ContentType
    */
    dynamic var contentType: Int = 0
    dynamic var createdAt: Date = Date()
    dynamic var updatedAt: Date = Date()
    
    dynamic var room: Room?
    dynamic var from: User?
    dynamic var text: String?
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
}

extension Transcript {
    
    convenience init(id: String, text: String, from: User, room: Room) {
        self.init()
        self.id = id
        self.text = text
        self.from = from
        self.room = room
    }
    
}
