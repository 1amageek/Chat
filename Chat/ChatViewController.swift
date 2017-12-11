//
//  ChatViewController.swift
//  Chat
//
//  Created by 1amageek on 2017/01/30.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit
import Toolbar

class ChatViewController: ViewController, UICollectionViewDelegate {

    var toolbarBottomConstraint: NSLayoutConstraint?

    override func loadView() {
        super.loadView()
        self.view.backgroundColor = .white
        self.view.addSubview(collectionView)
        self.view.addSubview(toolbar)
        self.toolbarBottomConstraint = self.toolbar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0)
        self.toolbarBottomConstraint?.isActive = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .automatic
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        layoutChatView()
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

    override func viewWillLayoutSubviews() {
        self.collectionView.frame = self.view.bounds
    }

    func layoutChatView() {
        var contentInset: UIEdgeInsets = collectionView.contentInset
        contentInset.top = contentInsetTop
        contentInset.bottom = toolBarHeight
        collectionView.scrollIndicatorInsets = contentInset
        contentInset.top = contentInsetTop + 8
        contentInset.bottom = toolBarHeight + 8
        collectionView.contentInset = contentInset
    }

    // Keyboard

    var contentInsetTop: CGFloat {
        if #available(iOS 11.0, *) {
            return 0
        }
        return (self.navigationController?.navigationBar.frame.height ?? 0) + UIApplication.shared.statusBarFrame.height
    }

    private var toolBarHeight: CGFloat {
        return self.keyboardHeight + self.toolbar.bounds.height
    }

    private var keyboardHeight: CGFloat = 0

    @objc final func keyboardWillShow(notification: Notification) {
        moveToolbar(up: true, notification: notification)
    }

    @objc final func keyboardWillHide(notification: Notification) {
        moveToolbar(up: false, notification: notification)
    }

    var propertyAnimator: UIViewPropertyAnimator?

    final func moveToolbar(up: Bool, notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        let animationDuration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        //let animationCurve: UIViewAnimationCurve = UIViewAnimationCurve(rawValue: (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).intValue)!
        self.keyboardHeight = up ? (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height : 0
        self.toolbarBottomConstraint?.constant = -self.keyboardHeight
        
        // Animation
        self.layoutChatView()
        UIView.animate(withDuration: animationDuration, delay: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {

            self.view.layoutIfNeeded()
        }, completion: nil)
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

    private(set) lazy var toolbar: Toolbar = {
        let toolbar: Toolbar = Toolbar()
        toolbar.maximumHeight = 100
        return toolbar
    }()

}

extension ChatViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

}
