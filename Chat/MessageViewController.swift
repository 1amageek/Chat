//
//  MessageViewController.swift
//  Chat
//
//  Created by 1amageek on 2017/02/14.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit
import Firebase
import RealmSwift

class MessageViewController: ChatViewController {

    var room: Room!
    
    lazy var user: FIRUser? = {
        guard let user: FIRUser = FIRAuth.auth()?.currentUser else {
            return nil
        }
        return user
    }()
    
    private(set) var datasource: Datasource<Firebase.Room, Firebase.Message>?
    
    private(set) lazy var sessionController: ChatSessionController = {
        let controller: ChatSessionController = ChatSessionController(realm: self.realm, room: self.room)
        return controller
    }()
    
    override func loadView() {
        super.loadView()
        self.collectionView.register(ChatTextRightCell.self, forCellWithReuseIdentifier: "ChatTextRightCell")
        self.collectionView.register(ChatTextLeftCell.self, forCellWithReuseIdentifier: "ChatTextLeftCell")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fixedSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpace.width = 16
        
        self.toolBar.setItems([
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            self.sendBarButtonItem,
            fixedSpace
            ], animated: false)
        
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
                    
                    guard let userID: String = message.userID else {
                        return
                    }
                    
                    guard let text: String = message.text else {
                        return
                    }
                    
                    try! self?.realm.write {                        
                        let transcript: Transcript = Transcript()
                        transcript.id = message.id
                        transcript.text = text
                        transcript.roomID = room.id
                        transcript.userID = userID
                        self?.realm.add(transcript, update: true)
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
                        print(key)
                        // TODO: connect Realm
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
    
    private(set) lazy var sendBarButtonItem: UIBarButtonItem = {
        let barButtonItem: UIBarButtonItem = UIBarButtonItem(title: "Send", style: .plain, target: self, action: #selector(send))
        barButtonItem.isEnabled = false
        return barButtonItem
    }()
    
    func send() {        
        let text: String = self.toolBar.textView.text
        self.sessionController.send(text: text, realm: self.realm) { [weak self](error) in
            if let error: ChatError = error {
                print(error)
                return
            }
            
            self?.toolBar.textView.text = ""
            self?.layoutToolbar()
            self?.sendBarButtonItem.isEnabled = false
        }
    }
    
    // MARK: - Datasorce
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.transcripts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let transcript: Transcript = self.transcripts[indexPath.item]
        
        switch Chat.ContentType(rawValue: transcript.contentType)! {
        case .text:
            if self.user!.uid == transcript.userID {
                let cell: ChatTextRightCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatTextRightCell", for: indexPath) as! ChatTextRightCell
                cell.text = transcript.text
                return cell
            } else {
                let cell: ChatTextLeftCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatTextLeftCell", for: indexPath) as! ChatTextLeftCell
                cell.text = transcript.text
                return cell
            }
        default:
            let cell: ChatViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatViewCell", for: indexPath) as! ChatViewCell
            return cell
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let transcript: Transcript = self.transcripts[indexPath.item]
        
        switch Chat.ContentType(rawValue: transcript.contentType)! {
        case .text:
            if self.user!.uid == transcript.userID {
                let cell: ChatTextRightCell = ChatTextRightCell(frame: self.view.bounds)
                cell.name = "name"
                cell.text = transcript.text
                return cell.calculateSize()
            } else {
                let cell: ChatTextLeftCell = ChatTextLeftCell(frame: self.view.bounds)
                cell.name = "name"
                cell.text = transcript.text
                return cell.calculateSize()
            }
        default: return .zero
        }
        
    }

    // MARK: - UITextViewDelegate
    
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        self.sendBarButtonItem.isEnabled = textView.text.characters.count > 0
    }
    
    // MARK: - Realm
    
    let realm = try! Realm()
    
    private(set) var notificationToken: NotificationToken?
    
    private(set) lazy var transcripts: Results<Transcript> = {
        var transcripts: Results<Transcript> = self.realm.objects(Transcript.self).filter("roomID == %@", self.room.id).sorted(byKeyPath: "updatedAt")
        self.notificationToken = transcripts.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
            guard let collectionView: ChatView = self?.collectionView else { return }
            switch changes {
            case .initial:
                collectionView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                collectionView.performBatchUpdates({
                    collectionView.insertItems(at: insertions.map { IndexPath(item: $0, section: 0) })
                    collectionView.deleteItems(at: deletions.map { IndexPath(item: $0, section: 0) })
                    collectionView.reloadItems(at: modifications.map { IndexPath(item: $0, section: 0) })
                }) { (finished) in
                    collectionView.scrollToBottom(true)
                }
            case .error(let error):
                fatalError("\(error)")
                break
            }
        }
        return transcripts
    }()
    
    deinit {
        self.notificationToken?.stop()
    }
    
}

