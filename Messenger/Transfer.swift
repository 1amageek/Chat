//
//  Transfer.swift
//  Chat
//
//  Created by 1amageek on 2017/03/01.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import Foundation
import Photos
import Firebase

class Transfer {
    
    static let shared: Transfer = Transfer()
    
    let sessionQueue = DispatchQueue(label: "transfer_session_queue", attributes: [], target: nil)
    
    let imageManager: PHCachingImageManager = PHCachingImageManager()
    
    let imageSize: CGSize = CGSize(width: 2500, height: 2500)
    
    let compressionRate: CGFloat = 0.75
    
    func upload(_ item: Item) {
        
        self.sessionQueue.async {
            let options: PHFetchOptions = PHFetchOptions()
            options.includeAssetSourceTypes = .typeUserLibrary
            guard let asset: PHAsset = PHAsset.fetchAssets(withLocalIdentifiers: [item.localIdentifier], options: options).firstObject else {
                return
            }
            
            switch asset.mediaType {
            case .image:
                let options: PHImageRequestOptions = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.resizeMode = .none
                options.isNetworkAccessAllowed = false
                options.isSynchronous = true
                
                item.requestID = self.imageManager.requestImage(for: asset, targetSize: self.imageSize, contentMode: .aspectFit, options: options, resultHandler: { (image, userInfo) in
                    guard let image: UIImage = image else {
                        return
                    }
                    let data: Data = UIImageJPEGRepresentation(image, self.compressionRate)!
                    let file: Salada.File = Salada.File(data: data)
                })
            case .video: break
            case .audio: break
            case .unknown: break
            }
            
        }
        
    }
    
    
    
}

extension Transfer {
    class Item {
        let localIdentifier: String
        let progress: Progress = Progress()
        var requestID: PHImageRequestID?
        
        init(localIdentifier: String) {
            self.localIdentifier = localIdentifier
        }
        
    }
}
