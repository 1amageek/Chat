//
//  HMAC.swift
//  Chat
//
//  Created by 1amageek on 2017/02/06.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import Foundation

extension String {
    func SHA1(key: String) -> Data {
        let str = self.cString(using: .utf8)
        let strLen = Int(self.lengthOfBytes(using: .utf8))
        let digestLen = Int(CC_SHA1_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        let keyStr = key.cString(using: .utf8)
        let keyLen = Int(key.lengthOfBytes(using: .utf8))
        
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), keyStr!, keyLen, str!, strLen, result)
        return Data(bytes: result, count: digestLen)
    }
}
