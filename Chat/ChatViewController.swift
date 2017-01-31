//
//  ChatViewController.swift
//  Chat
//
//  Created by 1amageek on 2017/01/30.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit
import RealmSwift

class ChatViewController: UIViewController, UICollectionViewDelegate {
    
    var room: Room?
    
    override func loadView() {
        super.loadView()
        self.view.backgroundColor = .white
        self.view.addSubview(collectionView)
        self.view.addSubview(toolBar)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        view.register(ChatViewCell.self, forCellWithReuseIdentifier: "ChatViewCell")
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
    
    // MARK: - Realm
    
    let realm = try! Realm()
    
    private(set) var notificationToken: NotificationToken?
    
    private(set) lazy var transcripts: Results<Transcript> = {
        var transcripts: Results<Transcript> = self.realm.objects(Transcript.self).sorted(byKeyPath: "createdAt")
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

extension ChatViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        layoutToolbar()
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        textView.scrollRangeToVisible(textView.selectedRange)
    }
}
