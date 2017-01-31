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
        case sticker
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

protocol ChatCommunicable {
    
    func send(transcript: Transcript, complition: ((Error?) -> Void)?) -> Void
    func receive() -> Void
    
}

protocol ChatDataSourceProtocol {
    
    static func sizeForItem(_ transcript: Transcript) -> CGSize
    
}
