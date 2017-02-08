//
//  SessionController.swift
//  Chat
//
//  Created by 1amageek on 2017/02/08.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import Foundation

protocol SessionDelegate: NSObjectProtocol {
    func sessionController(_ controller:SessionController, didReceive message: Message) -> Void
}

class SessionController: NSObject {
    
    weak var delegate: SessionDelegate?
    
    func send(message: Message, block: () -> Void) {
        EchoServer.post(message: message) { [weak self](message) in
            self?.receive(message: message)
        }
        block()
    }
    
    func receive(message: Message) {
        self.delegate?.sessionController(self, didReceive: message)
    }
    
}
