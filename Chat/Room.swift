//
//  Room.swift
//  Chat
//
//  Created by 1amageek on 2017/02/14.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import Foundation

class Room: Salada.Object {
    
    dynamic var name: String?
    dynamic var members: Set<String> = []
    dynamic var messages: Set<String> = []
    
}
