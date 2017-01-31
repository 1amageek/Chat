//
//  MessageViewCell.swift
//  Chat
//
//  Created by 1amageek on 2017/01/31.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit

class MessageViewCell: UICollectionViewCell {
    
    enum Direction {
        case left
        case right
    }
    
    var direction: Direction = .left
    
    var message: String? {
        didSet {
            self.messageLabel.text = message
            self.setNeedsLayout()
        }
    }
    
    var date: String? {
        didSet {
            self.dateLabel.text = date
            self.setNeedsLayout()
        }
    }
    
    private let contentInset: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    private let balloonImageLeft: UIImage = #imageLiteral(resourceName: "bubble-left")
    private let balloonImageRight: UIImage = #imageLiteral(resourceName: "bubble-right")
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(balloonImageView)
        self.contentView.addSubview(dateLabel)
        self.contentView.addSubview(messageLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.balloonImageView.image = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        _ = calculateSize()
    }
    
    var messageMaxWidth: CGFloat {
        return self.bounds.width * 0.65
    }
    
    let balloonLeftInset: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    let balloonRightInset: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    
    func calculateSize() -> CGSize {
        
        self.dateLabel.sizeToFit()
        
        let frame: CGRect = CGRect(x: 0, y: 0, width: messageMaxWidth, height: self.bounds.height)
        let constraintSize: CGSize = UIEdgeInsetsInsetRect(frame, contentInset).size
        let messageLabelSize: CGSize = self.messageLabel.sizeThatFits(constraintSize)
        switch direction {
        case .left:
            balloonImageView.image = balloonImageLeft.resizableImage(withCapInsets: balloonLeftInset, resizingMode: .stretch)
            balloonImageView.frame = CGRect(x: contentInset.left,
                                            y: 0,
                                            width: messageMaxWidth + balloonLeftInset.left + balloonLeftInset.right,
                                            height: self.bounds.height)
            messageLabel.frame = CGRect(x: balloonImageView.frame.minX + balloonLeftInset.left,
                                        y: balloonLeftInset.top,
                                        width: messageMaxWidth,
                                        height: messageLabelSize.height)
        case .right:
            balloonImageView.image = balloonImageRight.resizableImage(withCapInsets: balloonRightInset, resizingMode: .stretch)
            let balloonImageWidth: CGFloat = messageMaxWidth + balloonRightInset.left + balloonRightInset.right
            balloonImageView.frame = CGRect(x: self.bounds.width - balloonImageWidth - contentInset.right,
                                            y: 0,
                                            width: balloonImageWidth,
                                            height: self.bounds.height)
            messageLabel.frame = CGRect(x: balloonImageView.frame.minX + balloonLeftInset.left,
                                        y: balloonRightInset.top,
                                        width: messageMaxWidth,
                                        height: messageLabelSize.height)
        }
    
        return CGSize(width: self.bounds.width, height: self.messageLabel.frame.maxY + self.contentInset.bottom)
    }
    
    // MARK: -
    
    private(set) lazy var balloonImageView: UIImageView = {
        let view: UIImageView = UIImageView(frame: .zero)
        view.clipsToBounds = true
        return view
    }()
    
    private(set) lazy var dateLabel: UILabel = {
        let label: UILabel = UILabel(frame: .zero)
        label.numberOfLines = 1
        return label
    }()
    
    private(set) lazy var messageLabel: UILabel = {
        let label: UILabel = UILabel(frame: .zero)
        label.numberOfLines = 0
        return label
    }()
        
}
