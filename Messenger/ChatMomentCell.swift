//
//  ChatMomentCell.swift
//  Chat
//
//  Created by 1amageek on 2017/03/06.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit
import Firebase

class ChatMomentCell: ChatViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var momentID: String? {
        didSet {
            
            if let momentID: String = self.momentID {
                let options: SaladaOptions = SaladaOptions()
                options.limit = 10
                options.ascending = false
                self.datasource = Datasource(parentKey: momentID, referenceKey: "images", options: options, block: { [weak self](changes) in
                    guard let collectionView: UICollectionView = self?.collectionView else { return }
                    switch changes {
                    case .initial:
                        collectionView.reloadData()
                    case .update(let deletions, let insertions, let modifications):
                        collectionView.performBatchUpdates({
                            collectionView.insertItems(at: insertions.map { IndexPath(item: $0, section: 0) })
                            collectionView.deleteItems(at: deletions.map { IndexPath(item: $0, section: 0) })
                            collectionView.reloadItems(at: modifications.map { IndexPath(item: $0, section: 0) })
                        }) { (finished) in
                            
                        }
                    case .error(let error):
                        fatalError("\(error)")
                        break
                    }
                })
            } else {
                self.collectionView.reloadData()
            }
            
        }
    }
    
    private(set) var datasource: Datasource<Firebase.Moment, Firebase.Image>?
    
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
    
    override func calculateSize() -> CGSize {
        let size: CGSize = CGSize(width: self.bounds.width, height: contentInset.top + itemSize.height + contentInset.bottom)
        self.collectionView.frame = CGRect(origin: .zero, size: size)
        return size
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.datasource = nil
    }
    
    private(set) lazy var collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let view: UICollectionView = UICollectionView(frame: self.bounds, collectionViewLayout: layout)
        view.delegate = self
        view.dataSource = self
        view.register(ChatMomentItemCell.self, forCellWithReuseIdentifier: "ChatMomentItemCell")
        return view
    }()
    
    // MARK: -
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.datasource?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ChatMomentItemCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatMomentItemCell", for: indexPath) as! ChatMomentItemCell
        return cell
    }
    
    func configure(cell: ChatMomentItemCell, at indexPath: IndexPath) {
        self.datasource?.object(at: indexPath.item, block: { (image) in
            guard let image: Firebase.Image = image else {
                return
            }
            if let ref: FIRStorageReference = image.file?.ref {
//                cell.imageView.
            }
        })
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

extension ChatMomentCell {
    
    class ChatMomentItemCell: UICollectionViewCell {
        
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
