//
//  ChatSessionController.swift
//  Chat
//
//  Created by 1amageek on 2017/02/16.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import Foundation
import RealmSwift
import Firebase

class ChatSessionController {

    var realm: Realm
    
    var room: Room
    
    init(realm: Realm, room: Room) {
        self.realm = realm
        self.room = room
    }
        
    func send(text: String, realm: Realm, block: ((ChatError?) -> Void)?) {
        
        guard let user: FIRUser = FIRAuth.auth()?.currentUser else {
            block?(.authorization)
            return
        }
        
        let ref: FIRDatabaseReference = Firebase.Message.databaseRef.childByAutoId()        
        do {
            try realm.write {
                let transcript: Transcript = Transcript()
                transcript.id = ref.key
                transcript.userID = user.uid
                transcript.roomID = room.id
                transcript.text = text
                realm.add(transcript)                
                block?(nil)
                
                let message: Firebase.Message = Firebase.Message(id: ref.key)!
                message.userID = user.uid
                message.roomID = room.id
                message.text = text
                message.save({ (ref, error) in
                    // TODO: retry function
                })
                
            }
        } catch {
            
        }
        
    }
    
}
