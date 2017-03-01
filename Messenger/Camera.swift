//
//  Camera.swift
//  Camera
//
//  Created by 1amageek on 2017/01/09.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class Camera: NSObject {
    
    weak var previewView: PreviewView!
    
    var videoDeviceInput: AVCaptureDeviceInput!
    
    let photoOutput: AVCapturePhotoOutput = AVCapturePhotoOutput()
    
    var movieFileOutput: AVCaptureMovieFileOutput?
    
    var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
    let videoDeviceDiscoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera], mediaType: AVMediaTypeVideo, position: .unspecified)!
    
    // Session running callback
    
    var sessionRunningBlock: ((Bool) -> Void)?
    
    // Movie recording callback
    
    var didStartRecordingBlock: (() -> Void)?
    
    var didFinishRecordingBlock: ((Error?) -> Void)?
    
    // Capture mode
    enum CaptureMode {
        
        // In this mode, you can shoot LivePhoto
        case photo
        
        // You can only shoot movies
        case movie
        
        // LivePhoto shooting can not be performed in this mode
        case both
    }
    
    private(set) var captureMode: CaptureMode = .photo
    
    // LivePhoto mode
    enum LivePhotoMode {
        case on
        case off
    }
    
    private(set) var livePhotoMode: LivePhotoMode = .on
    
    var inProgressLivePhotoCapturesCount: Int = 0
    
    var inProgressPhotoCaptureDelegates: [Int64 : PhotoCaptureDelegate] = [:]
    
    init(previewView: PreviewView) {
        super.init()
        self.previewView = previewView
        self.previewView.session = session
        let tapGestureRecoginzer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(focusAndExposeTap(_:)))
        self.previewView.addGestureRecognizer(tapGestureRecoginzer)
    }
    
    enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    let session: AVCaptureSession = AVCaptureSession()
    
    var isSessionRunning: Bool = false
    
    var setupResult: SessionSetupResult = .success
    
    // Communicate with the session and other session objects on this queue.
    let sessionQueue = DispatchQueue(label: "camera_session_queue", attributes: [], target: nil)
    
    var sessionPreset: String {
        switch livePhotoMode {
        case .off: return AVCaptureSessionPresetHigh
        case .on: return AVCaptureSessionPresetPhoto
        }
    }
    
    // Call this on the session queue.
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        defer {
            session.commitConfiguration()
        }
        
        session.beginConfiguration()
        
        /*
         We do not create an AVCaptureMovieFileOutput when setting up the session because the
         AVCaptureMovieFileOutput does not support movie recording with AVCaptureSessionPresetPhoto.
         */
        session.sessionPreset = AVCaptureSessionPresetPhoto
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera if available, otherwise default to a wide angle camera.
            if let dualCameraDevice: AVCaptureDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInDualCamera, mediaType: AVMediaTypeVideo, position: .back) {
                defaultVideoDevice = dualCameraDevice
            }
            else if let backCameraDevice: AVCaptureDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back) {
                // If the back dual camera is not available, default to the back wide angle camera.
                defaultVideoDevice = backCameraDevice
            }
            else if let frontCameraDevice: AVCaptureDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) {
                // In some cases where users break their phones, the back wide angle camera is not available. In this case, we should default to the front wide angle camera.
                defaultVideoDevice = frontCameraDevice
            }
            
            let videoDeviceInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    /*
                     Why are we dispatching this to the main queue?
                     Because AVCaptureVideoPreviewLayer is the backing layer for PreviewView and UIView
                     can only be manipulated on the main thread.
                     Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                     
                     Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
                     handled by CameraViewController.viewWillTransition(to:with:).
                     */
                    let statusBarOrientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if statusBarOrientation != .unknown {
                        if let videoOrientation: AVCaptureVideoOrientation = statusBarOrientation.videoOrientation {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    
                    self.previewView.videoPreviewLayer.connection.videoOrientation = initialVideoOrientation
                }
            }
            else {
                print("Could not add video device input to the session")
                setupResult = .configurationFailed
                return
            }
        }
        catch {
            print("Could not create video device input: \(error)")
            setupResult = .configurationFailed
            return
        }
        
        // Add audio input.
        do {
            let audioDevice: AVCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
            let audioDeviceInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            }
            else {
                print("Could not add audio device input to the session")
            }
        }
        catch {
            print("Could not create audio device input: \(error)")
        }
        
        // Add photo output.
        if session.canAddOutput(photoOutput)
        {
            session.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
            livePhotoMode = photoOutput.isLivePhotoCaptureSupported ? .on : .off
        }
        else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            return
        }
    }
    
    // MARK: KVO and Notifications
    
    private var sessionRunningObserveContext: Int = 0
    
    private func addObservers() {
        session.addObserver(self, forKeyPath: "running", options: .new, context: &sessionRunningObserveContext)
        NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange(notification:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError(notification:)), name: NSNotification.Name.AVCaptureSessionRuntimeError, object: session)
        
        /*
         A session can only run when the app is full screen. It will be interrupted
         in a multi-app layout, introduced in iOS 9, see also the documentation of
         AVCaptureSessionInterruptionReason. Add observers to handle these session
         interruptions and show a preview is paused message. See the documentation
         of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
         */
        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted(notification:)), name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded(notification:)), name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: session)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        session.removeObserver(self, forKeyPath: "running", context: &sessionRunningObserveContext)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &sessionRunningObserveContext {
            let newValue = change?[.newKey] as AnyObject?
            guard let isSessionRunning = newValue?.boolValue else { return }
            DispatchQueue.main.async {
                self.sessionRunningBlock?(isSessionRunning)
            }
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: -
    
    func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .autoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
    }
    
    func sessionRuntimeError(notification: NSNotification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
            return
        }
        
        let error = AVError(_nsError: errorValue)
        print("Capture session runtime error: \(error)")
        
        /*
         Automatically try to restart the session running if media services were
         reset and the last start running succeeded. Otherwise, enable the user
         to try to resume the session running.
         */
        if error.code == .mediaServicesWereReset {
            sessionQueue.async { [unowned self] in
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                }
                else {
                    DispatchQueue.main.async { [unowned self] in
//                        self.resumeButton.isHidden = false
                    }
                }
            }
        }
        else {
//            resumeButton.isHidden = false
        }
    }
    
    func sessionWasInterrupted(notification: NSNotification) {
        /*
         In some scenarios we want to enable the user to resume the session running.
         For example, if music playback is initiated via control center while
         using AVCam, then the user can let AVCam resume
         the session running, which will stop music playback. Note that stopping
         music playback in control center will not automatically resume the session
         running. Also note that it is not always possible to resume, see `resumeInterruptedSession(_:)`.
         */
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?, let reasonIntegerValue = userInfoValue.integerValue, let reason = AVCaptureSessionInterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
            
            var showResumeButton = false
            
            if reason == AVCaptureSessionInterruptionReason.audioDeviceInUseByAnotherClient || reason == AVCaptureSessionInterruptionReason.videoDeviceInUseByAnotherClient {
                showResumeButton = true
            }
            else if reason == AVCaptureSessionInterruptionReason.videoDeviceNotAvailableWithMultipleForegroundApps {
                // Simply fade-in a label to inform the user that the camera is unavailable.
//                cameraUnavailableLabel.alpha = 0
//                cameraUnavailableLabel.isHidden = false
//                UIView.animate(withDuration: 0.25) { [unowned self] in
//                    self.cameraUnavailableLabel.alpha = 1
//                }
            }
            
            if showResumeButton {
//                // Simply fade-in a button to enable the user to try to resume the session running.
//                resumeButton.alpha = 0
//                resumeButton.isHidden = false
//                UIView.animate(withDuration: 0.25) { [unowned self] in
//                    self.resumeButton.alpha = 1
//                }
            }
        }
    }
    
    func sessionInterruptionEnded(notification: NSNotification) {
        print("Capture session interruption ended")
        
//        if !resumeButton.isHidden {
//            UIView.animate(withDuration: 0.25,
//                           animations: { [unowned self] in
//                            self.resumeButton.alpha = 0
//                }, completion: { [unowned self] finished in
//                    self.resumeButton.isHidden = true
//                }
//            )
//        }
//        if !cameraUnavailableLabel.isHidden {
//            UIView.animate(withDuration: 0.25,
//                           animations: { [unowned self] in
//                            self.cameraUnavailableLabel.alpha = 0
//                }, completion: { [unowned self] finished in
//                    self.cameraUnavailableLabel.isHidden = true
//                }
//            )
//        }
    }
    
    private func resumeInterruptedSession()
    {
        sessionQueue.async { [unowned self] in
            /*
             The session might fail to start running, e.g., if a phone or FaceTime call is still
             using audio or video. A failure to start the session running will be communicated via
             a session runtime error notification. To avoid repeatedly failing to start the session
             running, we only try to restart the session running in the session runtime error handler
             if we aren't trying to resume the session running.
             */
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
            if !self.session.isRunning {
                DispatchQueue.main.async { [unowned self] in
//                    let message = NSLocalizedString("Unable to resume", comment: "Alert message when unable to resume the session running")
//                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
//                    let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil)
//                    alertController.addAction(cancelAction)
//                    self.present(alertController, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async { [unowned self] in
//                    self.resumeButton.isHidden = true
                }
            }
        }
    }
    
    @objc private func focusAndExposeTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let devicePoint = self.previewView.videoPreviewLayer.captureDevicePointOfInterest(for: gestureRecognizer.location(in: gestureRecognizer.view))
        focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
    }
    
    private func focus(with focusMode: AVCaptureFocusMode, exposureMode: AVCaptureExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        sessionQueue.async { [unowned self] in
            if let device = self.videoDeviceInput.device {
                do {
                    try device.lockForConfiguration()
                    
                    /*
                     Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                     Call set(Focus/Exposure)Mode() to apply the new point of interest.
                     */
                    if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                        device.focusPointOfInterest = devicePoint
                        device.focusMode = focusMode
                    }
                    
                    if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                        device.exposurePointOfInterest = devicePoint
                        device.exposureMode = exposureMode
                    }
                    
                    device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                    device.unlockForConfiguration()
                }
                catch {
                    print("Could not lock device for configuration: \(error)")
                }
            }
        }
    }
    
    // MARK: - 
    
    func configure(completion: ((Bool) -> Void)?) {
        self.sessionRunningBlock = completion
        sessionQueue.async { [unowned self] in
            self.configureSession()
        }
    }
    
    func startSession(completion: ((Bool) -> Void)?) {
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session running if setup succeeded.
                self.addObservers()
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                DispatchQueue.main.async {
                    completion?(true)
                }
            case .notAuthorized:
                DispatchQueue.main.async {
                    completion?(false)
                }
            case .configurationFailed:
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { 
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                self.removeObservers()
            }
        }
    }
    
    /**
     Change LivePhotoMode
    */
    
    func change(livePhotoMode: LivePhotoMode, completion: (() -> Void)?) {
        
        if self.livePhotoMode == livePhotoMode {
            return
        }
        
        sessionQueue.async { [unowned self] in
            self.livePhotoMode = livePhotoMode
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    /**
     Change capture mode
     */
    func change(captureMode: CaptureMode = .photo, completion: (() -> Void)?) {

        if self.captureMode == captureMode {
            return
        }
        
        self.captureMode = captureMode
        
        switch captureMode {
        case .photo:
            sessionQueue.async { [unowned self] in
                /*
                 Remove the AVCaptureMovieFileOutput from the session because movie recording is
                 not supported with AVCaptureSessionPresetPhoto. Additionally, Live Photo
                 capture is not supported when an AVCaptureMovieFileOutput is connected to the session.
                 */
                self.session.beginConfiguration()
                self.session.removeOutput(self.movieFileOutput)
                self.session.sessionPreset = AVCaptureSessionPresetPhoto
                self.session.commitConfiguration()
                
                self.movieFileOutput = nil
                
                if self.photoOutput.isLivePhotoCaptureSupported {
                    self.photoOutput.isLivePhotoCaptureEnabled = true
                    
                    DispatchQueue.main.async {
                        completion?()
                    }
                }
            }
        case .movie:
            sessionQueue.async { [unowned self] in
                let movieFileOutput = AVCaptureMovieFileOutput()
                
                if self.session.canAddOutput(movieFileOutput) {
                    self.session.beginConfiguration()
                    self.session.addOutput(movieFileOutput)
                    self.session.sessionPreset = AVCaptureSessionPresetHigh
                    if let connection = movieFileOutput.connection(withMediaType: AVMediaTypeVideo) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                    self.session.commitConfiguration()
                    
                    self.movieFileOutput = movieFileOutput
                    
                    DispatchQueue.main.async {
                        completion?()
                    }
                }
            }
        case .both:
            
            sessionQueue.async { [unowned self] in
                
                if self.livePhotoMode != .off {
                    print("[Camera] To use both mode you need to turn off livePhotoMode.")
                    return
                }
                
                let movieFileOutput = AVCaptureMovieFileOutput()
                
                if self.session.canAddOutput(movieFileOutput) {
                    self.session.beginConfiguration()
                    self.session.addOutput(movieFileOutput)
                    self.session.sessionPreset = AVCaptureSessionPresetHigh
                    if let connection = movieFileOutput.connection(withMediaType: AVMediaTypeVideo) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                    self.session.commitConfiguration()
                    
                    self.movieFileOutput = movieFileOutput
                    
                    DispatchQueue.main.async {
                        completion?()
                    }
                }
            }
        }
        
    }

    /**
     Change camera
    */
    func changeCamera(completion: (() -> Void)?) {
        
        sessionQueue.async { [unowned self] in
            let currentVideoDevice: AVCaptureDevice = self.videoDeviceInput.device
            let currentPosition: AVCaptureDevicePosition = currentVideoDevice.position
            
            let preferredPosition: AVCaptureDevicePosition
            let preferredDeviceType: AVCaptureDeviceType
            
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInWideAngleCamera
            }
            
            let devices = self.videoDeviceDiscoverySession.devices!
            var newVideoDevice: AVCaptureDevice? = nil
            
            // First, look for a device with both the preferred position and device type. Otherwise, look for a device with only the preferred position.
            if let device = devices.filter({ $0.position == preferredPosition && $0.deviceType == preferredDeviceType }).first {
                newVideoDevice = device
            }
            else if let device = devices.filter({ $0.position == preferredPosition }).first {
                newVideoDevice = device
            }
            
            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    self.session.beginConfiguration()
                    
                    // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
                    self.session.removeInput(self.videoDeviceInput)
                    
                    if self.session.canAddInput(videoDeviceInput) {
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: currentVideoDevice)
                        
                        NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange(notification:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: videoDeviceInput.device)
                        
                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    }
                    else {
                        self.session.addInput(self.videoDeviceInput);
                    }
                    
                    if let connection = self.movieFileOutput?.connection(withMediaType: AVMediaTypeVideo) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                    
                    /*
                     Set Live Photo capture enabled if it is supported. When changing cameras, the
                     `isLivePhotoCaptureEnabled` property of the AVCapturePhotoOutput gets set to NO when
                     a video device is disconnected from the session. After the new video device is
                     added to the session, re-enable Live Photo capture on the AVCapturePhotoOutput if it is supported.
                     */
                    self.photoOutput.isLivePhotoCaptureEnabled = self.photoOutput.isLivePhotoCaptureSupported;
                    
                    self.session.commitConfiguration()
                }
                catch {
                    print("Error occured while creating video device input: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    deinit {
        debugPrint("Camera deinit")
    }
    
}

// MARK: - Extension

extension UIDeviceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        default: return nil
        }
    }
}

extension UIInterfaceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        default: return nil
        }
    }
}

extension AVCaptureDeviceDiscoverySession {
    func uniqueDevicePositionsCount() -> Int {
        var uniqueDevicePositions = [AVCaptureDevicePosition]()
        
        for device in devices {
            if !uniqueDevicePositions.contains(device.position) {
                uniqueDevicePositions.append(device.position)
            }
        }
        
        return uniqueDevicePositions.count
    }
}
