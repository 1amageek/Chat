//
//  RoomViewCell.swift
//  Chat
//
//  Created by 1amageek on 2017/02/14.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit

class RoomViewCell: UITableViewCell {
    
    var thumbnailImage: UIImage? {
        didSet {
            self.thumbnailImageView.image = thumbnailImage
            self.thumbnailImageView.setNeedsDisplay()
        }
    }
    
    var title: String? {
        didSet {
            self.titleLabel.text = title
            self.setNeedsLayout()
        }
    }
    
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
    
    let imageViewRadius: CGFloat = 32
    let contentInset: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(thumbnailImageView)
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(dateLabel)
        self.contentView.addSubview(messageLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let imageViewDiameter: CGFloat = imageViewRadius * 2
        thumbnailImageView.frame = CGRect(x: contentInset.left, y: contentInset.top, width: imageViewDiameter, height: imageViewDiameter)
        let constraintSize: CGSize = CGSize(width: self.bounds.width - thumbnailImageView.frame.maxX - contentInset.left, height: CGFloat.greatestFiniteMagnitude)
        let titleLabelSize: CGSize = self.titleLabel.sizeThatFits(constraintSize)
        titleLabel.frame = CGRect(x: thumbnailImageView.frame.maxX + 8, y: contentInset.top, width: titleLabelSize.width, height: titleLabelSize.height)
        let messageLabelSize: CGSize = self.messageLabel.sizeThatFits(constraintSize)
        messageLabel.frame = CGRect(x: titleLabel.frame.minX, y: titleLabel.frame.maxY + 8, width: messageLabelSize.width, height: messageLabelSize.height)
        dateLabel.sizeToFit()
        dateLabel.frame = CGRect(x: self.bounds.width - contentInset.right - dateLabel.bounds.width, y: contentInset.top, width: dateLabel.bounds.width, height: dateLabel.bounds.height)
    }
    
    private(set) lazy var thumbnailImageView: UIImageView = {
        let imageView: UIImageView = UIImageView(frame: .zero)
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = self.imageViewRadius
        return imageView
    }()
    
    private(set) lazy var titleLabel: UILabel = {
        let label: UILabel = UILabel(frame: .zero)
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    private(set) lazy var messageLabel: UILabel = {
        let label: UILabel = UILabel(frame: .zero)
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    private(set) lazy var dateLabel: UILabel = {
        let label: UILabel = UILabel(frame: .zero)
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 10)
        return label
    }()

}
