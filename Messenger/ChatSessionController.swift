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
    
    private(set) var datasource: Datasource<Firebase.Room, Firebase.Message>?
    
    init(realm: Realm, room: Room) {
        self.realm = realm
        self.room = room
        
        let options: SaladaOptions = SaladaOptions()
        options.limit = 30
        options.ascending = false
        
        self.datasource = Datasource(parentKey: self.room.id, referenceKey: "messages", options: options, block: { [weak self](changes) in
            
            guard let room: Room = self?.room else { return }
            
            let insertBlock = { (index) in
                self?.datasource?.observeObject(at: index, block: { (message) in
                    
                    guard let message: Firebase.Message = message else {
                        return
                    }
                    
                    // UserIDを持っている
                    guard let userID: String = message.userID else {
                        return
                    }
                    
                    // 定義済みのContentTypeである
                    // ContentTypeが新しく定義されても以前のバージョンでは表示されない
                    guard let contentType: Chat.ContentType = Chat.ContentType(rawValue: message.contentType) else {
                        return
                    }
                    
                    if let transcript: Transcript = self?.realm.objects(Transcript.self).filter("id == %@", message.id).first {
                        if transcript.updatedAt <= message.updatedAt {
                            return
                        }
                    }
                    
                    let transcript: Transcript = Transcript()
                    transcript.id = message.id
                    transcript.contentType = contentType.rawValue
                    transcript.createdAt = message.createdAt
                    transcript.updatedAt = message.updatedAt
                    transcript.roomID = room.id
                    transcript.userID = userID
                    transcript.contentID = message.contentID
                    
                    switch contentType {
                    case .text:
                        transcript.text = message.text
                        try! self?.realm.write {
                            self?.realm.add(transcript, update: true)
                        }
                    case .image: break
                    case .video: break
                    case .audio: break
                    case .location: break
                    case .sticker: break
                    case .imageMap: break
                    case .moment:
                        guard let contentID: String = message.contentID else {
                            return
                        }
                        Firebase.Moment.observeSingle(contentID, eventType: .value, block: { (moment) in
                            guard let moment: Firebase.Moment = moment as? Firebase.Moment else {
                                return
                            }
                            let realmMoment: Moment = Moment()
                            realmMoment.id = moment.id
                            realmMoment.roomID = moment.roomID
                            realmMoment.createdAt = moment.createdAt
                            realmMoment.updatedAt = moment.updatedAt

                            try! self?.realm.write {
                                self?.realm.add(transcript, update: true)
                            }
                        })
                    case .template: break
                    }
                    
                    
                    
                    
                    
                })
            }
            
            
            switch changes {
            case .initial:
                
                let count: Int = self?.datasource?.count ?? 0
                (0..<count).forEach({ (index) in
                    insertBlock(index)
                })
                
            case .update(let deletions, let insertions, let modifications):
                
                
                insertions.forEach({ (index) in
                    insertBlock(index)
                })
                
                deletions.forEach({ (index) in
                    self?.datasource?.removeObject(at: index, cascade: false, block: { (key, error) in
                        if let error: Error = error {
                            debugPrint(error)
                            return
                        }
                        if let transcript: Transcript = self?.realm.objects(Transcript.self).filter("id == %@", key).first {
                            try! self?.realm.write {
                                self?.realm.delete(transcript)
                            }
                        }
                    })
                })
                
                modifications.forEach({ (index) in
                    self?.datasource?.observeObject(at: index, block: { (message) in
                        guard let room: Firebase.Message = message else {
                            return
                        }
                        print(room)
                        // TODO: Connect Realm
                    })
                })
                
            case .error(let error):
                print(error)
            }
        })
        
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
                
                Firebase.Room.observeSingle(room.id, eventType: .value, block: { (room) in
                    guard let room: Firebase.Room = room as? Firebase.Room else {
                        return
                    }
                    let message: Firebase.Message = Firebase.Message(id: ref.key)!
                    message.userID = user.uid
                    message.roomID = room.id
                    message.text = text
                    message.save({ (ref, error) in                        
                        if let error = error {
                            debugPrint(error)
                            return
                        }
                        room.messages.insert(ref!.key)
                    })
                })
   
            }
        } catch {
            
        }
        
    }
    
}
