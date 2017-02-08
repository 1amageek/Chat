//
//  FollowersViewController.swift
//  Chat
//
//  Created by 1amageek on 2017/02/03.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit
import Accounts

class FollowersViewController: UITableViewController, NextLoding {

    var account: ACAccount!
    
    var users: [User] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    private weak var task: URLSessionDataTask?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _ = Session.oauthRequestToken { _ in
            _ = Session.followers { (users, cursor, error) in
                if let error: Error = error {
                    debugPrint(error)
                    return
                }
                self.users = users
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "FollowersViewCell", for: indexPath)
        cell.textLabel?.text = self.users[indexPath.item].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewController: ViewController = ViewController()
//        viewController.account = self.users[indexPath.item]
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if shouldNextLoding {            
            next()
        }
    }
    
    // MARK: -
    
    private var cursor: String = "-1"
    
    func next() {
        if self.task != nil {
            debugPrint("Busy", self.task!)
            return
        }
        self.task = Session.followers(cursor: self.cursor, block: { [weak self] (users, cursor, error) in
            guard let strongSelf = self else {
                return
            }
            
            if let error = error {
                debugPrint(error)
                return
            }
            
            strongSelf.users = strongSelf.users + users
            strongSelf.cursor = cursor
        })
    }

    deinit {
        self.task?.cancel()
    }

}

