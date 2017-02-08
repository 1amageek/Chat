//
//  JSONParsable.swift
//  Chat
//
//  Created by 1amageek on 2017/02/03.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import Foundation

protocol JSONParsable {
    
    init(_ json: [AnyHashable: Any])
    
}
