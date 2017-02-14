//
//  RoomViewController.swift
//  Chat
//
//  Created by 1amageek on 2017/02/14.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit
import Firebase
import RealmSwift

class RoomViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private(set) var datasource: Datasource<Firebase.User, Firebase.Room>?
    
    override func loadView() {
        super.loadView()
        self.view.addSubview(tableView)
    }
    
    func addRoom() {
        Firebase.User.current { (user) in
                                    
            guard let user: Firebase.User = user else {
                return
            }
            let room: Firebase.Room = Firebase.Room()
            room.members.insert(user.id)
            room.name = String(describing: Date())
            room.save({ (ref, error) in
                if let error: Error = error {
                    debugPrint(error)
                    return
                }
                user.rooms.insert(ref!.key)
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let user: FIRUser = FIRAuth.auth()?.currentUser else {
            return
        }
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "+", style: .plain, target: self, action: #selector(addRoom))
        
        
//        let options: SaladaOptions = SaladaOptions()
//        options.limit = 30
//        options.ascending = false
//        
//        self.datasource = Datasource(parentKey: user.uid, referenceKey: "rooms", options: options, block: { [weak self](changes) in
//            guard let tableView: UITableView = self?.tableView else { return }
//            switch changes {
//            case .initial:
//                tableView.reloadData()
//            case .update(let deletions, let insertions, let modifications):
//                
//                insertions.forEach({ (index) in
//                    self?.datasource?.observeObject(at: index, block: { (room) in
//                        guard let room: Room = room else {
//                            return
//                        }
//                        print(room)
//                        try! self?.realm.write {
//                            let chatRoom: Group = Group(id: room.id, name: room.name!)
//                            self?.realm.add(chatRoom)
//                        }
//                    })
//                })
//                
//                deletions.forEach({ (index) in
//                    self?.datasource?.removeObject(at: index, cascade: false, block: { (key, error) in
//                        if let error: Error = error {
//                            debugPrint(error)
//                            return
//                        }
//                        print(key)
//                        // TODO: connect Realm
//                    })
//                })
//                
//                modifications.forEach({ (index) in
//                    self?.datasource?.observeObject(at: index, block: { (room) in
//                        guard let room: Room = room else {
//                            return
//                        }
//                        print(room)
//                        // TODO: Connect Realm
//                    })
//                })
//                
//            case .error(let error):
//                print(error)
//            }
//        })
        
    }
    
    // MARK: -
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: RoomViewCell = tableView.dequeueReusableCell(withIdentifier: "RoomViewCell", for: indexPath) as! RoomViewCell
//        let room: Group = self.rooms[indexPath.item]
//        cell.title = room.name
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
    
    // MARK: - Realm
    
    let realm = try! Realm()
    
    private(set) var notificationToken: NotificationToken?
    
    private(set) lazy var rooms: Results<Group> = {
        var results: Results<Group> = self.realm.objects(Group.self).sorted(byKeyPath: "createdAt")
        self.notificationToken = results.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
            
            guard let tableView: UITableView = self?.tableView else { return }
            
            switch changes {
            case .initial:
                tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                tableView.endUpdates()
            case .error(let error):
                print(error)
            }
        }
        return results
    }()
    
    deinit {
        self.notificationToken?.stop()
    }

}
