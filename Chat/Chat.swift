//
//  Chat.swift
//  Chat
//
//  Created by 1amageek on 2017/01/31.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit
import RealmSwift

class Chat {
    
    enum ContentType: Int {
        case text
        case image
        case video
        case audio
        case location
        case sticker
        case moment
        case template
    }
    
    enum ChatError: Error {
        case network
        case database
    }
    
    class Session {
        class func send(transcript: Transcript, complition: ((ChatError?) -> Void)?) {
            
            let realm = try! Realm()
            do {
                try realm.write {
                    realm.add(transcript)
                    complition?(nil)
                }
            } catch {
                complition?(.database)
                return
            }
        }
    }
    
}

extension Chat {
    
    class User: Object {
        
        dynamic var id: String!
                
    }
    
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
    
    class Room: Object {
        
        dynamic var id: String!
        dynamic var createdAt: Date = Date()
        dynamic var updatedAt: Date = Date()
        
        dynamic var name: String!
        
        let members: List<Chat.User> = List<Chat.User>()
        
        override static func primaryKey() -> String? {
            return "id"
        }
        
        convenience init(id: String, name: String) {
            self.init()
            self.id = id
            self.name = name
        }
    }
    
}

extension Chat.Transcript {
    
    convenience init(id: String, text: String, from: Chat.User, room: Chat.Room) {
        self.init()
        self.id = id
        self.text = text
        self.from = from
        self.room = room
    }
    
}

protocol ChatCommunicable {
    
    func send(transcript: Chat.Transcript, complition: ((Error?) -> Void)?) -> Void
    func receive() -> Void
    
}

protocol ChatDataSourceProtocol {
    
    static func sizeForItem(_ transcript: Chat.Transcript) -> CGSize
    
}
