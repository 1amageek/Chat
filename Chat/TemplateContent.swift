//
//  TemplateContent.swift
//  Chat
//
//  Created by 1amageek on 2017/02/28.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import Foundation
import RealmSwift

class TemplateContent: Object {
    
    dynamic var id: String!

    dynamic var templateType: Int = 0
    dynamic var createdAt: Date = Date()
    dynamic var updatedAt: Date = Date()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
}
