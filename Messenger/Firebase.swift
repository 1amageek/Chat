//
//  Firebase.swift
//  Chat
//
//  Created by 1amageek on 2017/02/14.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import Foundation
import Firebase

class Firebase {
    
    class User: Salada.Object {
        
        typealias Element = User
        
        dynamic var name: String?
        dynamic var rooms: Set<String> = []
        
    }
    
    class Room: Salada.Object {
        
        typealias Element = Room
        
        dynamic var name: String?
        dynamic var members: Set<String> = []
        dynamic var messages: Set<String> = []
        
    }
    
    class Message: Salada.Object {
        
        typealias Element = Message
        
        dynamic var contentType: Int = 0
        dynamic var userID: String?
        dynamic var text: String?
        dynamic var contentID: String?
        
    }
    
}

extension Firebase.User {
    class func current(block: @escaping (Firebase.User?) -> Void) {
        guard let user: FIRUser = FIRAuth.auth()?.currentUser else {
            block(nil)
            return
        }
        Firebase.User.observeSingle(user.uid, eventType: .value) { (user) in
            block(user as? Firebase.User)
        }
    }
}
