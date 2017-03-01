//
//  ChatTemplateCell.swift
//  Chat
//
//  Created by 1amageek on 2017/02/28.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit

class ChatTemplateCell: ChatViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var datasource: [String] = []
    
    var itemSize: CGSize = CGSize(width: 180, height: 180)
    
    var margin: CGFloat = 8
    
    let contentInset: UIEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(collectionView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.datasource = []
    }
    
    private(set) lazy var collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let view: UICollectionView = UICollectionView(frame: self.bounds, collectionViewLayout: layout)
        view.delegate = self
        view.dataSource = self
        view.register(CardCell.self, forCellWithReuseIdentifier: "CardCell")
        return view
    }()
    
    // MARK: -
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.datasource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: CardCell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCell", for: indexPath) as! CardCell
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return itemSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return margin
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return margin
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return contentInset
    }
    
}

extension ChatTemplateCell {
    
    class CardCell: UICollectionViewCell {
        
        var image: UIImage? {
            didSet {
                self.imageView.image = image
                self.imageView.setNeedsDisplay()
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.contentView.addSubview(imageView)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            self.imageView.image = nil
        }
        
        private(set) lazy var imageView: UIImageView = {
            let view: UIImageView = UIImageView(frame: .zero)
            view.clipsToBounds = true
            view.contentMode = .scaleAspectFill
            return view
        }()
        
    }
    
}
