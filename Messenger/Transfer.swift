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
    
    var userID: String?
    
    let sessionQueue = DispatchQueue(label: "transfer_session_queue", attributes: [], target: nil)
    
    let imageManager: PHCachingImageManager = PHCachingImageManager()
    
    let imageSize: CGSize = CGSize(width: 2500, height: 2500)
    
    let compressionRate: CGFloat = 0.75
    
    func upload(_ item: Item, moment: Firebase.Moment? = nil, block: ((FIRDatabaseReference?, Error?) -> Void)?) {
        
        guard let userID: String = self.userID else {
            print("Transfer required userID.")
            return
        }
        
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
                    let img: Firebase.Image = Firebase.Image()
                    img.userID = userID
                    img.file = file
                    item.task = img.save({ (ref, error) in
                        moment?.images.insert(ref!.key)
                        block?(ref, error)
                    })["file"]

                })
                
            case .video: break
            case .audio: break
            case .unknown: break
            }
            
        }
        
    }
    
    
    
}

extension Transfer {
    class Item: Hashable {
        let localIdentifier: String
        var requestID: PHImageRequestID?
        var progressBlock: ((Progress?) -> Void)?
        
        var task: FIRStorageUploadTask? {
            didSet {
                _ = task?.observe(.progress, handler: { [weak self](snapshot) in
                    self?.progressBlock?(snapshot.progress)
                })
            }
        }
        
        init(localIdentifier: String) {
            self.localIdentifier = localIdentifier
        }
        
        deinit {
            self.task?.removeAllObservers()
        }
        
    }
}

extension Transfer.Item {
    var hashValue: Int {
        return self.localIdentifier.hash
    }
}

func == (lhs: Transfer.Item, rhs: Transfer.Item) -> Bool {
    return lhs.localIdentifier == rhs.localIdentifier
}
