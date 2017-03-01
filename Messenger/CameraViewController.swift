//
//  CameraViewController.swift
//  Camera
//
//  Created by 1amageek on 2017/01/09.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class CameraViewController: UIViewController {
    
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    
    @IBAction func flashButtonAction(_ sender: Any) {
        
    }
    
    @IBAction func cameraButtonAction(_ sender: Any) {
        self.view.isUserInteractionEnabled = false
        self.camera.changeCamera { [weak self] in
            self?.view.isUserInteractionEnabled = true
        }
    }
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var photoSaveFinished: ((Data?) -> Void)?
    
    lazy var camera: Camera = {
        let camera: Camera = Camera(previewView: self.previewView)
        return camera
    }()
    
    lazy var previewView: Camera.PreviewView = {
        let view: Camera.PreviewView = Camera.PreviewView(frame: self.view.bounds)
        return view
    }()
    
    lazy var triggerView: Camera.TriggerView = {
        let view: Camera.TriggerView = Camera.TriggerView()
        return view
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.view.insertSubview(previewView, at: 0)
        self.view.addSubview(triggerView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .authorized:
            // The user has previously granted access to the camera.
            break
            
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant
             video access. We suspend the session queue to delay session
             setup until the access request has completed.
             
             Note that audio access will be implicitly requested when we
             create an AVCaptureDeviceInput for audio during session setup.
             */
            self.camera.sessionQueue.suspend()
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { [unowned self] granted in
                if !granted {
                    self.camera.setupResult = .notAuthorized
                }
                self.camera.sessionQueue.resume()
            })
            
        default:
            // The user has previously denied access.
            self.camera.setupResult = .notAuthorized
        }
        
        // Configure camera
        self.camera.configure { [weak self](isRunnginSession) in
            self?.flashButton.isEnabled = isRunnginSession
            self?.cameraButton.isEnabled = isRunnginSession
            self?.triggerView.isEnabled = isRunnginSession
        }
        
        // Setting mode
        self.camera.change(livePhotoMode: .off, completion: nil)
        self.camera.change(captureMode: .both, completion: nil)
        
        // Photo
        self.triggerView.capture = { [weak self] in
            
            self?.flashButton.isHidden = true
            self?.cameraButton.isHidden = true
            
            self?.camera.capturePhoto(capturingLivePhotoBlock: { (inProgressLivePhotoCapturesCount) in
                
                // TODO: LivePhoto
                
            }) { [weak self] localIdentifier in
                
                if let localIdentifier: String = localIdentifier {
                    
                    let item: Transfer.Item = Transfer.Item(localIdentifier: localIdentifier)
                    Transfer.shared.upload(item)
                }
                
                self?.triggerView.toDefault(animated: false)
                self?.flashButton.isHidden = false
                self?.cameraButton.isHidden = false
            }
        }
        
        // Movie
        self.triggerView.recordingStart = { [weak self] in
            self?.flashButton.isHidden = true
            self?.cameraButton.isHidden = true
            
            if self?.camera.captureMode != .both {
                self?.camera.change(captureMode: .movie, completion: nil)
            }
            
            self?.camera.movieRecordingStart(completion: { 
                
            })
        }
        
        self.triggerView.recordingStop = { [weak self] in
            self?.camera.movieRecordingStop(completion: {  [weak self] (error) in
                self?.flashButton.isHidden = false
                self?.cameraButton.isHidden = false
            })
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.camera.startSession { (authorized) in
            if !authorized {
                // TODO: 
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.camera.stopSession()
    }
    
    override func viewWillLayoutSubviews() {
        triggerView.center = CGPoint(x: self.view.bounds.width / 2, y: self.view.bounds.height - 150)
    }
    
    deinit {
        debugPrint("CameraViewController deinit")
    }
    
}
