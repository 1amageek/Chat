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
    
    private let contentInset: UIEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    private let balloonImageLeft: UIImage = #imageLiteral(resourceName: "left_bubble")
    private let balloonImageRight: UIImage = #imageLiteral(resourceName: "right_bubble")
    
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
    
    var balloonMaxWidth: CGFloat {
        return self.bounds.width * 0.65
    }
    
    let leftMargin: CGFloat = 24
    let rightMargin: CGFloat = 24
    
    func calculateSize() -> CGSize {
        
        self.dateLabel.sizeToFit()
        
        let frame: CGRect = CGRect(x: 0, y: 0, width: balloonMaxWidth, height: self.bounds.height)
        let constraintSize: CGSize = UIEdgeInsetsInsetRect(frame, contentInset).size
        let messageLabelSize: CGSize = self.messageLabel.sizeThatFits(constraintSize)
        switch direction {
        case .left:
            self.messageLabel.textColor = .black
            let balloonLeftInset: UIEdgeInsets = UIEdgeInsets(top: balloonImageLeft.size.height / 2,
                                                              left: balloonImageLeft.size.width / 2,
                                                              bottom: balloonImageLeft.size.height / 2,
                                                              right: balloonImageLeft.size.width / 2)
            balloonImageView.image = balloonImageLeft.resizableImage(withCapInsets: balloonLeftInset, resizingMode: .stretch)
            balloonImageView.frame = CGRect(x: leftMargin,
                                            y: 0,
                                            width: messageLabelSize.width + contentInset.left + contentInset.right,
                                            height: self.bounds.height)
            messageLabel.frame = CGRect(x: balloonImageView.frame.minX + contentInset.left,
                                        y: contentInset.top,
                                        width: messageLabelSize.width,
                                        height: messageLabelSize.height)
        case .right:
            self.messageLabel.textColor = .white
            let balloonRightInset: UIEdgeInsets = UIEdgeInsets(top: balloonImageRight.size.height / 2,
                                                              left: balloonImageRight.size.width / 2,
                                                              bottom: balloonImageRight.size.height / 2,
                                                              right: balloonImageRight.size.width / 2)
            balloonImageView.image = balloonImageRight.resizableImage(withCapInsets: balloonRightInset, resizingMode: .stretch)
            let balloonImageWidth: CGFloat = messageLabelSize.width + contentInset.left + contentInset.right
            balloonImageView.frame = CGRect(x: self.bounds.width - balloonImageWidth - rightMargin,
                                            y: 0,
                                            width: balloonImageWidth,
                                            height: self.bounds.height)
            messageLabel.frame = CGRect(x: balloonImageView.frame.minX + contentInset.left,
                                        y: contentInset.top,
                                        width: messageLabelSize.width,
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
