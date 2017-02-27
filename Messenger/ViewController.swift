//
//  ViewController.swift
//  Chat
//
//  Created by 1amageek on 2017/02/17.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {

    @IBAction func tap(_ sender: Any) {

        Antenna.default.writeValueBlock = { (peripheral, characteristic) in
            let data: Data = "hoge".data(using: .utf8)!
            peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        }
        
        Antenna.default.startScan(thresholdRSSI: NSNumber(value: -28), allowDuplicates: true)
    }
    
    var observer: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.observer = NotificationCenter.default.addObserver(forName: .BeaconDidReceiveWriteNotificationKey, object: nil, queue: .main) { (notification) in


            let alertController: UIAlertController = UIAlertController(title: "ペアリング", message: "ペアリングしますか？", preferredStyle: .alert)
            let cancel: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let ok: UIAlertAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                
            })
            alertController.addAction(ok)
            alertController.addAction(cancel)
            self.present(alertController, animated: true, completion: nil)
        }
        
        
        Beacon.default.startAdvertising()
        
    }
    
    deinit {
        if let observer = self.observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
}
