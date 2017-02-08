//
//  ViewController.swift
//  TwitterMessenger
//
//  Created by 1amageek on 2017/01/31.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit
import Social
import Accounts

class ViewController: UIViewController, UICollectionViewDelegate, NextLoding {

    var user: User = User(id: "0000", name: "taro", screenName: "taro")
    var recipient: User = User(id: "0001", name: "kintaro", screenName: "kintaro")
    
    var messages: [Message] = [] {
        didSet {
            let new: Set<Message> = Set(messages)
            let old: Set<Message> = Set(oldValue)
            let indexPaths: [IndexPath] = new.subtracting(old).map({ return IndexPath(item: messages.index(of: $0)!, section: 0) })
            self.collectionView.performBatchUpdates({
                self.collectionView.insertItems(at: indexPaths)
            }, completion: { finished in
                self.collectionView.scrollToBottom(true)
            })
        }
    }
    
    weak var task: URLSessionDataTask?
    
    override func loadView() {
        super.loadView()
        self.view.backgroundColor = .white
        self.view.addSubview(collectionView)
        self.view.addSubview(toolBar)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.toolBar.setItems([self.flexibleBarButtonItem, self.sendBarButtonItem], animated: false)
        
        layoutToolbar()
        layoutChatView()
        self.view.layoutIfNeeded()
        self.collectionView.scrollToBottom(false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func layoutToolbar() {
        toolBar.sizeToFit()
        let toolBarOriginY = self.view.bounds.height - self.toolBar.bounds.height - self.keyboardHeight
        toolBar.frame = CGRect(x: 0, y: toolBarOriginY, width: self.toolBar.bounds.width, height: self.toolBar.bounds.height)
    }
    
    func layoutChatView() {
        var contentInset: UIEdgeInsets = collectionView.contentInset
        contentInset.bottom = toolBarHeight
        collectionView.contentInset = contentInset
        collectionView.scrollIndicatorInsets = contentInset
    }
    
    // Keyboard
    
    private var toolBarHeight: CGFloat {
        return self.keyboardHeight + self.toolBar.bounds.height
    }
    
    private var keyboardHeight: CGFloat = 0
    
    final func keyboardWillShow(notification: Notification) {
        moveToolbar(up: true, notification: notification)
    }
    
    final func keyboardWillHide(notification: Notification) {
        moveToolbar(up: false, notification: notification)
    }
    
    final func moveToolbar(up: Bool, notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        let animationDuration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let animationCurve: UIViewAnimationCurve = UIViewAnimationCurve(rawValue: (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).intValue)!
        self.keyboardHeight = up ? (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height : 0
        
        // Animation
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(animationDuration)
        UIView.setAnimationCurve(animationCurve)
        layoutToolbar()
        layoutChatView()
        UIView.commitAnimations()
        if up {
            self.collectionView.scrollToBottom(true)
        }
    }
    
    // MARK: -
    
    private(set) lazy var collectionView: ChatView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .vertical
        let view: ChatView = ChatView(frame: self.view.bounds, collectionViewLayout: layout)
        view.dataSource = self
        view.delegate = self
        view.alwaysBounceVertical = true
        view.alwaysBounceHorizontal = false
        view.register(MessageViewCell.self, forCellWithReuseIdentifier: "MessageViewCell")
        view.backgroundColor = .white
        view.keyboardDismissMode = .onDrag
        return view
    }()
    
    private(set) lazy var toolBar: ChatToolBar = {
        let toolbar: ChatToolBar = ChatToolBar()
        toolbar.textView.delegate = self
        toolbar.sizeToFit()
        return toolbar
    }()
    
    // MARK: -
    
    lazy var sessionController: SessionController = {
        let sessionController: SessionController = SessionController()
        sessionController.delegate = self
        return sessionController
    }()
    
    @objc private func send() {
        guard let text: String = self.toolBar.textView.text else {
            return
        }
        guard !text.isEmpty else {
            return
        }
        let uuid: String = UUID().uuidString
        let message: Message = Message(id: uuid, createdAt: Date(), text: text, recipient: self.recipient, sender: self.user)
        
        var messages: [Message] = self.messages
        messages.append(message)
        self.messages = messages.sorted(by: { return $0.createdAt < $1.createdAt })
        self.sessionController.send(message: message) { [weak self] in
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
    
    // MARK: - Loding

    func next() {

    }
}


extension ViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        layoutToolbar()
        self.sendBarButtonItem.isEnabled = self.toolBar.textView.text.characters.count > 0 ? true : false
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        textView.scrollRangeToVisible(textView.selectedRange)
    }
}

extension ViewController: SessionDelegate {
    
    func sessionController(_ controller: SessionController, didReceive message: Message) {        
        var messages: [Message] = self.messages
        messages.append(message)
        self.messages = messages.sorted(by: { return $0.createdAt < $1.createdAt })
    }
    
}

