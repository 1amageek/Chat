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
        
        dynamic var roomID: String?
        dynamic var contentType: Int = 0
        dynamic var userID: String?
        dynamic var text: String?
        dynamic var contentID: String?
        
    }
    
    class Image: Salada.Object {
        typealias Element = Image
    }
    
    class Video: Salada.Object {
        typealias Element = Video
    }
    
    class Audio: Salada.Object {
        typealias Element = Audio
    }
    
    class Location: Salada.Object {
        typealias Element = Location
    }
    
    class Sticker: Salada.Object {
        typealias Element = Sticker
    }
    
    class Template: Salada.Object {
        typealias Element = Template
        dynamic var templateType: Int = 0
    }
    
    class Card: Salada.Object {
        typealias Element = Card
        dynamic var items: Set<String> = []
    }
    
    class CardItem: Salada.Object {
        typealias Element = CardItem
        dynamic var image: Salada.File?
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
