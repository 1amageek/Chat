//
//  ViewController.swift
//  TwitterMessenger
//
//  Created by 1amageek on 2017/01/31.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit

class ViewController: ChatViewController {

    override func loadView() {
        super.loadView()
        self.collectionView.register(MessageViewCell.self, forCellWithReuseIdentifier: "MessageViewCell")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.toolBar.setItems([self.flexibleBarButtonItem, self.sendBarButtonItem], animated: false)
    }
    
    // MARK: -
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: MessageViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MessageViewCell", for: indexPath) as! MessageViewCell
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    func configure(cell: MessageViewCell, at indexPath: IndexPath) {
        let transcript: Transcript = self.transcripts[indexPath.item]
        guard let contentType: Chat.ContentType = Chat.ContentType(rawValue: transcript.contentType) else {
            print("unknown Chat contentType")
            // TODO: into placeholder
            return
        }
        
        switch contentType {
        case .text: cell.message = transcript.text
        default: break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cell: MessageViewCell = MessageViewCell(frame: self.view.bounds)
        let transcript: Transcript = self.transcripts[indexPath.item]
        
        guard let contentType: Chat.ContentType = Chat.ContentType(rawValue: transcript.contentType) else {
            print("unknown Chat contentType")
            // TODO: into placeholder
            return cell.calculateSize()
        }
        
        switch contentType {
        case .text: cell.message = transcript.text
        default: break
        }
        return cell.calculateSize()
    }
    
    // MARK: -
    
    @objc private func send() {
        guard let text: String = self.toolBar.textView.text else {
            return
        }
        guard !text.isEmpty else {
            return
        }
        
        let id: String = UUID().uuidString
        
        let user: User = User(id: "user_\(id)", name: "text")
        let room: Room = Room(id: "room_\(id)", name: "room")
        
        let transcript: Transcript = Transcript(id: "transcript_\(id)", text: text, from: user, room: room)
        Chat.Session.send(transcript: transcript) { [weak self](error) in
            if let error: Error = error {
                debugPrint(error)
                return
            }
            guard let strongSelf = self else {
                return
            }
            strongSelf.toolBar.textView.text = ""
            strongSelf.layoutToolbar()
            strongSelf.sendBarButtonItem.isEnabled = false
        }
    }
    
    private(set) lazy var sendBarButtonItem: UIBarButtonItem = {
        var sendBarButtonItem: UIBarButtonItem = UIBarButtonItem(title: "Send", style: .plain, target: self, action: #selector(send))
        sendBarButtonItem.isEnabled = false
        return sendBarButtonItem
    }()
    
    private(set) lazy var flexibleBarButtonItem: UIBarButtonItem = {
        var flexibleBarButtonItem: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        flexibleBarButtonItem.isEnabled = false
        return flexibleBarButtonItem
    }()
    
    // MARK: - 
    
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        self.sendBarButtonItem.isEnabled = self.toolBar.textView.text.characters.count > 0 ? true : false
    }

}
