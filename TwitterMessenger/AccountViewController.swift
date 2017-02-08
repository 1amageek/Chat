//
//  AccountViewController.swift
//  Chat
//
//  Created by 1amageek on 2017/02/01.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit
import Social
import Accounts

class AccountViewController: UITableViewController {
    
    let accountStroe: ACAccountStore = ACAccountStore()
    
    var accounts: [ACAccount] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    var account: ACAccount?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let accountType = accountStroe.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
        accountStroe.requestAccessToAccounts(with: accountType, options: nil) { (granted, error) in
            
            if let error: Error = error {
                debugPrint(error)
                return
            }
            
            if !granted {
                return
            }
            
            self.accounts = self.accountStroe.accounts(with: accountType) as! [ACAccount]
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.accounts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "AccountViewCell", for: indexPath)
        cell.textLabel?.text = self.accounts[indexPath.item].username
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Followers", bundle: nil)
        let viewController: FollowersViewController = storyBoard.instantiateInitialViewController() as! FollowersViewController
        viewController.account = self.accounts[indexPath.item]
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
}
