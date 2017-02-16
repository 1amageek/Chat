//
//  Realm+.swift
//  Chat
//
//  Created by 1amageek on 2017/02/16.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import Foundation
import RealmSwift

extension Object {
    
    class func findOne<T: Object>(id: String) -> T? {
        let realm = try! Realm()
        let object: T? = realm.objects(T.self).filter("id == %@", id).first
        return object
    }
    
}
