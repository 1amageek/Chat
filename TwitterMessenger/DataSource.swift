//
//  DataSource.swift
//  Chat
//
//  Created by 1amageek on 2017/02/01.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: MessageViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MessageViewCell", for: indexPath) as! MessageViewCell
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    func configure(cell: MessageViewCell, at indexPath: IndexPath) {
        let message: Message = self.messages[indexPath.item]
        cell.direction = message.sender == self.user ? .right : .left
        cell.message = message.text
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cell: MessageViewCell = MessageViewCell(frame: self.view.bounds)
        let message: Message = self.messages[indexPath.item]
        cell.message = message.text
        return cell.calculateSize()
    }
    
}
