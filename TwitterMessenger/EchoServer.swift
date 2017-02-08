//
//  EchoServer.swift
//  Chat
//
//  Created by 1amageek on 2017/02/08.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import Foundation

class EchoServer {
    
    class func post(message: Message, block: @escaping (Message) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            
            (0..<2).forEach({ (index) in
                let uuid: String = UUID().uuidString
                let message: Message = Message(id: uuid, createdAt: Date(), text: message.text, recipient: message.sender, sender: message.recipient)
                block(message)
            })
            
        }
    }
    
}
