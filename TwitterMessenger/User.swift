//
//  User.swift
//  Chat
//
//  Created by 1amageek on 2017/02/03.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import Foundation

struct User: Hashable {
    
    let id: String
    let name: String
    let screenName: String
    var profileImageURL: URL?
    
    var hashValue: Int {
        return self.id.hash
    }
    
    init(id: String, name: String, screenName: String) {
        self.id = id
        self.name = name
        self.screenName = screenName
    }
    
}

func == (lhs: User, rhs: User) -> Bool {
    return lhs.id == rhs.id
}

extension User: JSONParsable {
    init(_ json: [AnyHashable : Any]) {
        
        let id: String = json["id_str"] as! String
        let name: String = json["name"] as! String
        let screenName: String = json["screen_name"] as! String
        let profileImageURLStr: String = json["profile_image_url_https"] as! String
        let profileImageURL: URL = URL(string: profileImageURLStr)!
        
        self.id = id
        self.name = name
        self.screenName = screenName
        self.profileImageURL = profileImageURL
        
    }
}
