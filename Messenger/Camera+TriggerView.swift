//
//  Camera+TriggerView.swift
//  Camera
//
//  Created by 1amageek on 2017/01/10.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit

extension Camera {
    
    class TriggerView: UIView {
        
        var isEnabled: Bool {
            set {
                self.isUserInteractionEnabled = isEnabled
                self.trigger.alpha = isEnabled ? 1 : 0.5
            }
            get {
                return self.isUserInteractionEnabled
            }
        }
        
        var minimumAroundRadius: CGFloat = 44
        
        var maximumAroundRadius: CGFloat = 72
        
        var minimumTriggerRadius: CGFloat = 26
        
        var maximumTriggerRadius: CGFloat = 30
        
        let pressDuration: CFTimeInterval = 0.2
        
        var capture: (() -> Void)?
        
        var recordingStart: (() -> Void)?
        
        var recordingStop: (() -> Void)?
        
        private(set) lazy var tapGestureRecognizer: UITapGestureRecognizer = {
            let recognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
            return recognizer
        }()
        
        private(set) lazy var longPressGestureRecognizer: UILongPressGestureRecognizer = {
            let recognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture(_:)))
            recognizer.minimumPressDuration = self.pressDuration
            return recognizer
        }()
        
        private(set) lazy var aroundView: UIVisualEffectView = {
            let effect: UIBlurEffect = UIBlurEffect(style: .light)
            let view: UIVisualEffectView = UIVisualEffectView(effect: effect)
            let diameter: CGFloat = self.minimumAroundRadius * 2
            let frame: CGRect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
            view.frame = frame
            view.clipsToBounds = true
            view.layer.cornerRadius = self.minimumAroundRadius
            return view
        }()
        
        private(set) lazy var trigger: UIView = {
            let view: UIView = UIView(frame: .zero)
            view.backgroundColor = .white
            view.clipsToBounds = true
            return view
        }()
        
        convenience init() {
            self.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor = .clear
            addSubview(aroundView)
            addSubview(trigger)
            trigger.addGestureRecognizer(tapGestureRecognizer)
            trigger.addGestureRecognizer(longPressGestureRecognizer)
            defaultLayout()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func toDefault(animated: Bool) {
            if animated {
                UIView.animate(withDuration: 0.33) {
                    self.defaultLayout()
                }
            } else {
                self.defaultLayout()
            }
        }
        
        private func defaultLayout() {
            aroundView.transform = .identity
            aroundView.frame = CGRect(x: 0, y: 0, width: self.minimumAroundRadius * 2, height: self.minimumAroundRadius * 2)
            aroundView.layer.cornerRadius = self.minimumAroundRadius
            aroundView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
            aroundView.alpha = 1
            trigger.transform = .identity
            trigger.frame = CGRect(x: 0, y: 0, width: self.maximumTriggerRadius * 2, height: self.maximumTriggerRadius * 2)
            trigger.layer.cornerRadius = self.maximumTriggerRadius
            trigger.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
            trigger.alpha = 1
        }
        
        private func captureLayout() {
            let scale: CGFloat = self.minimumTriggerRadius / self.maximumTriggerRadius
            trigger.transform = CGAffineTransform(scaleX: scale, y: scale)
            trigger.alpha = 0.5
        }
        
        private func recordingPrepareLayout() {
            let scale: CGFloat = self.minimumTriggerRadius / self.maximumTriggerRadius
            trigger.transform = CGAffineTransform(scaleX: scale, y: scale)
            trigger.alpha = 0.5
        }
        
        private func recordingLayout() {
            let scale: CGFloat = self.maximumAroundRadius / self.minimumAroundRadius
            aroundView.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
        
        // MARK: -
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            UIView.animate(withDuration: self.pressDuration) { 
                self.recordingPrepareLayout()
            }
        }
        
        @objc private func tapGesture(_ recognizer: UITapGestureRecognizer) {
            debugPrint("[TriggerView] trigger tapped.")
            UIView.animate(withDuration: 0.1) { 
                self.defaultLayout()
            }
            capture?()
        }
        
        @objc private func longPressGesture(_ recognizer: UILongPressGestureRecognizer) {
            let status: UIGestureRecognizerState = recognizer.state
            switch status {
            case .began:
                debugPrint("[TriggerView] trigger press start.")
                UIView.animate(withDuration: 0.33, animations: { 
                    self.recordingLayout()
                })
                recordingStart?()
            case .changed: break
            default:
                debugPrint("[TriggerView] trigger press end.")
                recordingStop?()
            }
        }
        
    }
    
}
