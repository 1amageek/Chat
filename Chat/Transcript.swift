//
//  Transcript.swift
//  Chat
//
//  Created by 1amageek on 2017/02/14.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import Foundation
import RealmSwift

class Transcript: Object {
    
    dynamic var id: String!
    
    /**
     - SeeAlso: Chat.ContentType
     */
    dynamic var contentType: Int = 0
    dynamic var createdAt: Date = Date()
    dynamic var updatedAt: Date = Date()
    
    dynamic var roomID: String?
    dynamic var userID: String?
    dynamic var text: String?
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
}
