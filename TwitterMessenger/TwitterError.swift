//
//  TwitterError.swift
//  Chat
//
//  Created by 1amageek on 2017/02/03.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import Foundation

struct TwitterError {
    
    let code: Int
    let message: String
    
}

extension TwitterError: JSONParsable {
    init(_ json: [AnyHashable : Any]) {
        
        let code: Int = json["code"] as! Int
        let message: String = json["message"] as! String
        
        self.code = code
        self.message = message
        
    }
}
