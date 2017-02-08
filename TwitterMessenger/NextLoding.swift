//
//  NextLoding.swift
//  Chat
//
//  Created by 1amageek on 2017/02/03.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit

protocol NextLoding {
    
    var shouldNextLoding: Bool { get }
    
    func next() -> Void
    
}

extension NextLoding where Self: UITableViewController {
    
    var shouldNextLoding: Bool {
        if self.tableView.bounds.height < self.tableView.contentSize.height {
            let offset: CGFloat = self.tableView.contentSize.height - self.tableView.bounds.height
            return self.tableView.contentOffset.y > offset
        } else {
            return false
        }
    }
    
}

extension NextLoding where Self: ViewController {
    
    var shouldNextLoding: Bool {
        if self.collectionView.bounds.height < self.collectionView.contentSize.height {
            let offset: CGFloat = self.collectionView.contentSize.height - self.collectionView.bounds.height
            return self.collectionView.contentOffset.y > offset
        } else {
            return false
        }
    }
    
}
