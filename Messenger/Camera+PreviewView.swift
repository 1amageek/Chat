//
//  Camera+PreviewView.swift
//  Camera
//
//  Created by 1amageek on 2017/01/09.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

extension Camera {
    class PreviewView: UIView {
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
        
        var session: AVCaptureSession? {
            get {
                return videoPreviewLayer.session
            }
            set {
                videoPreviewLayer.session = newValue
            }
        }
        
        // MARK: UIView
        
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
    }
}
