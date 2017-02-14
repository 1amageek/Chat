//
//  User.swift
//  Chat
//
//  Created by 1amageek on 2017/02/14.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import Foundation
import Firebase

class User: Salada.Object {
    
    dynamic var name: String?
    dynamic var rooms: Set<String> = []
    
}
