//
//  AppDelegate.swift
//  Spend Stack
//
//  Created by Jordan Morgan on 8/7/20.
//  Copyright © 2020 Jordan Morgan. All rights reserved.
//

import UIKit
import AVKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Schema, keyboard handling toolbar and ratings prompt setup
        SSDataStore.sharedInstance().createDatabaseSchemaIfNeeded()
        
        IQKeyboardManager.shared().isEnableAutoToolbar = false
        RatingsPrompter.sharedInstance().numberOfAppLaunchesRequired = 5
        RatingsPrompter.sharedInstance().logAppLaunchAndInstallDateIfNeeded()
        
        SSAppearanceProxy.setTintThemeForUIKitControls()

        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let incomingNotification = CKNotification(fromRemoteNotificationDictionary: userInfo) {
            switch incomingNotification.notificationType {
            case .query:
                print("Spend Stack - CKQuery came in.")
            case .recordZone:
                print("Spend Stack - Push notification came in for record zone, processing updates.")
                let zoneNotification = incomingNotification as! CKRecordZoneNotification
                let name = NSNotification.Name(SS_CK_MANAGER_HANDLE_CHANGE_NOTIFICATION)
                NotificationCenter.default.post(name: name, object: zoneNotification)
            case .database:
                print("Spend Stack - Push notification came in for database, processing updates.")
                let databaseNotification = incomingNotification as! CKDatabaseNotification
                let name = NSNotification.Name(SS_CK_MANAGER_HANDLE_CHANGE_NOTIFICATION)
                NotificationCenter.default.post(name: name, object: databaseNotification)
            default:
                print("Spend Stack - Received unknown CKNotification type.")
            }
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        config.delegateClass = ListsSceneDelegate.classForCoder()
        return config
    }
}
