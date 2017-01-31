//
//  Room.swift
//  Chat
//
//  Created by 1amageek on 2017/01/31.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import RealmSwift

class Room: Object {
    
    dynamic var id: String!
    dynamic var createdAt: Date = Date()
    dynamic var updatedAt: Date = Date()
    
    dynamic var name: String!
    
    let members: List<User> = List<User>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(id: String, name: String) {
        self.init()
        self.id = id
        self.name = name
    }
    
}
