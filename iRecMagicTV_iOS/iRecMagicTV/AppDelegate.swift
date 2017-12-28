//
//  AppDelegate.swift
//  iRecMagicTV
//
//  Created by Stark Wong on 2015/04/25.
//  Copyright (c) 2015年 Studio KUMA. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var iRecLibrary: IRecLibrary = IRecLibrary.sharedInstance()

    class func getAppDelegate() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        var reallang: String? = userDefaults.objectForKey("lang") as? String;
        
        if reallang == nil {
            // reallang = (NSLocale.preferredLanguages()[0] as! String).hasPrefix("zh") ? "CHI" : "ENG"
            reallang = NSLocale.currentLocale().localeIdentifier.hasPrefix("zh") ? "CHI" : "ENG"
        }
        
        if reallang == "CHI" {
            reallang = "zh-Hant"
        } else {
            reallang = "Base"
        }
        
        userDefaults.setObject([reallang!], forKey:"AppleLanguages")
        userDefaults.synchronize() //to make the change immediate
        
        NSBundle.setLanguage(reallang)
        
        let notificationSettings: UIUserNotificationSettings=UIUserNotificationSettings(forTypes: UIUserNotificationType.Alert | UIUserNotificationType.Sound, categories: nil)
        
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
        
        let adController:CJPAdController=CJPAdController.sharedInstance()
        
        adController.adNetworks=[2]
        adController.adPosition=CJPAdPosition.Bottom
        adController.adMobUnitID=""
        adController.startWithViewController(self.window!.rootViewController)
        self.window!.rootViewController=adController
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

