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
import CoreBluetooth

class RoomViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private(set) var datasource: Datasource<Firebase.User, Firebase.Room>?
    
    override func loadView() {
        super.loadView()
        self.view.addSubview(tableView)
    }
    
    func addRoom() {
        
        guard let user: FIRUser = FIRAuth.auth()?.currentUser else {
            return
        }
        
        Antenna.default.writeValueBlock = { (peripheral, characteristic) in
            let data: Data = user.uid.data(using: .utf8)!
            peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        }
        
        Antenna.default.startScan(thresholdRSSI: NSNumber(value: -28), allowDuplicates: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let user: FIRUser = FIRAuth.auth()?.currentUser else {
            return
        }

        NotificationCenter.default.addObserver(forName: .BeaconDidReceiveWriteNotificationKey, object: nil, queue: .main) { (notification) in
            guard let userInfo: [AnyHashable: Any] = notification.userInfo else {
                return
            }
            guard let data: Data = userInfo[Beacon.ReceiveWriteDataKey] as? Data else {
                return
            }
            guard let userID: String = String(data: data, encoding: .utf8) else {
                return
            }
            
            let alertController: UIAlertController = UIAlertController(title: "ペアリング", message: "ペアリングしますか？", preferredStyle: .alert)
            let cancel: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let ok: UIAlertAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                Firebase.User.observeSingle(userID, eventType: .value, block: { (user) in
                    guard let partner: Firebase.User = user as? Firebase.User else {
                        return
                    }
                    
                    Firebase.User.current { (user) in
                        guard let user: Firebase.User = user else {
                            return
                        }
                        let room: Firebase.Room = Firebase.Room()
                        room.members.insert(user.id)
                        room.members.insert(partner.id)
                        room.name = String(describing: Date())
                        room.save({ (ref, error) in
                            if let error: Error = error {
                                debugPrint(error)
                                return
                            }
                            partner.rooms.insert(ref!.key)
                            user.rooms.insert(ref!.key)
                        })
                    }
                    
                })
            })
            alertController.addAction(ok)
            alertController.addAction(cancel)
            self.present(alertController, animated: true, completion: nil)
        }
        
        Beacon.default.startAdvertising()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "+", style: .plain, target: self, action: #selector(addRoom))
        
        let options: SaladaOptions = SaladaOptions()
        options.limit = 30
        options.ascending = false

        self.datasource = Datasource(parentKey: user.uid, referenceKey: "rooms", options: options, block: { [weak self](changes) in
            
            let insertBlock = { (index) in
                self?.datasource?.observeObject(at: index, block: { (room) in
                    
                    guard let strongSelf = self else {
                        return
                    }
                    
                    guard let room: Firebase.Room = room else {
                        return
                    }
                    
                    let roomID: String = room.id
                    
                    // すでに持っていれば作らない
                    if strongSelf.realm.objects(Room.self).contains(where: { (room) -> Bool in
                        return roomID == room.id
                    }) {
                        return
                    }
                    
                    try! self?.realm.write {
                        let chatRoom: Room = Room(id: room.id, name: room.name!)
                        self?.realm.add(chatRoom)
                    }
                })
            }
            
            switch changes {
            case .initial:
                let count: Int = self?.datasource?.count ?? 0
                (0..<count).forEach({ (index) in
                    insertBlock(index)
                })
                
            case .update(let deletions, let insertions, let modifications):
                
                insertions.forEach({ (index) in
                    insertBlock(index)
                })
                
                deletions.forEach({ (index) in
                    self?.datasource?.removeObject(at: index, cascade: false, block: { (key, error) in
                        if let error: Error = error {
                            debugPrint(error)
                            return
                        }
                        print(key)
                        // TODO: connect Realm
                    })
                })
                
                modifications.forEach({ (index) in
                    self?.datasource?.observeObject(at: index, block: { (room) in
                        guard let room: Firebase.Room = room else {
                            return
                        }
                        print(room)
                        // TODO: Connect Realm
                    })
                })
                
            case .error(let error):
                print(error)
            }
        })
        
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
        let room: Room = self.rooms[indexPath.item]
        cell.title = room.name
        return cell
    }
    
    // MARK: -
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewController: MessageViewController = MessageViewController()
        viewController.room = self.rooms[indexPath.item]
        self.navigationController?.pushViewController(viewController, animated: true)
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
    
    private(set) lazy var rooms: Results<Room> = {
        var results: Results<Room> = self.realm.objects(Room.self).sorted(byKeyPath: "createdAt")
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
        NotificationCenter.default.removeObserver(self)
        self.notificationToken?.stop()
    }

}
