//
//  AppDelegate.swift
//  Chat
//
//  Created by 1amageek on 2017/01/30.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        NSSetUncaughtExceptionHandler { exception in
            debugPrint(exception.name)
            debugPrint(exception.reason ?? "")
            debugPrint(exception.callStackSymbols)
        }
        
        FIRApp.configure()
                        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = UINavigationController(rootViewController: RoomViewController())
        self.window?.makeKeyAndVisible()
        
        return true
    }

}
