//
//  AppDelegate.swift
//  Messenger
//
//  Created by 1amageek on 2017/02/14.
//  Copyright © 2017年 Stamp inc. All rights reserved.
//

import UIKit
import Firebase
import RealmSwift

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
        //try! FIRAuth.auth()?.signOut()
        if let _: FIRUser = FIRAuth.auth()?.currentUser {
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.rootViewController = UINavigationController(rootViewController: RoomViewController())
            self.window?.makeKeyAndVisible()
        } else {
            FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in
                if let error: Error = error {
                    debugPrint(error)
                    return
                }
                let user: Firebase.User = Firebase.User(id: user!.uid)!
                user.name = "user"
                user.save({ (ref, error) in
                    
                    self.window = UIWindow(frame: UIScreen.main.bounds)
                    self.window?.rootViewController = UINavigationController(rootViewController: RoomViewController())
                    self.window?.makeKeyAndVisible()

                })
            })
        }                
        
        return true
    }

}

