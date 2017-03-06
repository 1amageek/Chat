//
//  Moment.swift
//  Chat
//
//  Created by 1amageek on 2017/03/06.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import Foundation
import RealmSwift

class Moment: Object {
    
    dynamic var id: String!
    dynamic var createdAt: Date = Date()
    dynamic var updatedAt: Date = Date()
    dynamic var startDate: Date = Date()
    dynamic var endDate: Date = Date()
    dynamic var roomID: String?
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
}
