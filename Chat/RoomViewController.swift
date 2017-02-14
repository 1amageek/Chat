//
//  RoomViewController.swift
//  Chat
//
//  Created by 1amageek on 2017/02/14.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit

class RoomViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    override func loadView() {
        super.loadView()
        self.view.addSubview(tableView)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    // MARK: -
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: RoomViewCell = tableView.dequeueReusableCell(withIdentifier: "RoomViewCell", for: indexPath) as! RoomViewCell
        return cell
    }
    
    // MARK: -
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    // MARK: -
    
    private(set) lazy var tableView: UITableView = {
        let view: UITableView = UITableView(frame: self.view.bounds, style: .grouped)
        view.backgroundColor = .white
        view.delegate = self
        view.dataSource = self
        view.register(RoomViewCell.self, forCellReuseIdentifier: "RoomViewCell")
        return view
    }()
    
    
}
