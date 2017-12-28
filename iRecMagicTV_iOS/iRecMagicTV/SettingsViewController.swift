//
//  SettingsViewController.swift
//  iRecMagicTV
//
//  Created by Stark Wong on 2015/04/25.
//  Copyright (c) 2015年 Studio KUMA. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    
    }

    override func viewWillAppear(animated: Bool) {
        /*
        let userDefaults: NSUserDefaults = NSUserDefaults()
        var cell:UITableViewCell
        
        cell=tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))!
        cell.detailTextLabel!.text=userDefaults.objectForKey("username") as? String
        
        cell=tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0))!
        cell.detailTextLabel!.text=userDefaults.objectForKey("device") as? String
*/
    }
    
    override func viewDidAppear(animated: Bool) {
        let userDefaults: NSUserDefaults = NSUserDefaults()
        var cell:UITableViewCell
        
        cell=tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))!
        cell.detailTextLabel!.text=userDefaults.objectForKey("username") as? String
        
        cell=tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0))!
        cell.detailTextLabel!.text=userDefaults.objectForKey("device") as? String
        
        cell=tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1))!
        
        var lang: String? = userDefaults.objectForKey("lang") as? String
        if lang == nil {
            lang = "Auto"
        } else if lang! == "ENG" {
            lang = "English"
        } else if lang! == "CHI" {
            lang = "Chinese"
        }
        
        cell.detailTextLabel!.text = lang!
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        
        let userDefaults: NSUserDefaults = NSUserDefaults()
        
        if cell.reuseIdentifier! == "username" {
            cell.detailTextLabel!.text=userDefaults.objectForKey("username") as? String
        } else if cell.reuseIdentifier! == "device" {
            cell.detailTextLabel!.text=userDefaults.objectForKey("device") as? String
        }
        
        return cell;
    }*/
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell:UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        
        switch cell.reuseIdentifier! {
        case "username":
            let alertController: UIAlertController = UIAlertController(title: "sf_logout".localized, message: "sf_logout_message".localized, preferredStyle: UIAlertControllerStyle.Alert);
            alertController.addAction(UIAlertAction(title: "cancel".localized, style: UIAlertActionStyle.Cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "sf_logout_clear_logout".localized, style: UIAlertActionStyle.Destructive, handler: { (alertAction: UIAlertAction!) -> Void in
                
                let userDefaults: NSUserDefaults = NSUserDefaults()
                userDefaults.removeObjectForKey("username")
                userDefaults.removeObjectForKey("password")
                userDefaults.removeObjectForKey("device")
                userDefaults.synchronize()
                
                self.cleanup()
                
                IRecLibrary.clearSession()
                
                AppDelegate.getAppDelegate().window!.rootViewController=UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? UIViewController
            }));
            self.presentViewController(alertController, animated: true, completion: nil)
        case "device":
            IRecLibrary.sharedInstance().getUnitList({ (objectType, result) -> Void in
                if objectType == IRecLibrary.ObjectType.DEVICES {
                    let devices:[Device] = result as! [Device]
                    
                    if count(devices) > 0 {
                        let alertController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
                        var alertAction: UIAlertAction
                        
                        let callback: (alertAction: UIAlertAction!) -> Void = {(alertAction: UIAlertAction!) -> Void in
                            let index = find(alertController.actions as! [UIAlertAction],alertAction)!
                            
                            let device: Device! = devices[index]
                            
                            IRecLibrary.sharedInstance().changeDevice(device.href, callback: { (objectType, result) -> Void in
                                if objectType == IRecLibrary.ObjectType.EMPTY {
                                    AppDelegate.getAppDelegate().window!.rootViewController=UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? UIViewController
                                }
                            })
                        }
                        
                        for device: Device in devices {
                            alertAction = UIAlertAction(title: device.name, style: UIAlertActionStyle.Default, handler: callback)
                            alertController.addAction(alertAction)
                        }
                        
                        alertController.addAction(UIAlertAction(title: "cancel".localized, style: UIAlertActionStyle.Cancel, handler: nil))
                        
                        
                        self.presentViewController(alertController, animated: true, completion: nil)
                    }
                }
            })
        case "language":
            let alertController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
            var alertAction: UIAlertAction
            
            let callback: (alertAction: UIAlertAction!) -> Void = {(alertAction: UIAlertAction!) -> Void in
                let index = find(alertController.actions as! [UIAlertAction],alertAction)!
                let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
                
                if index == 0 {
                    userDefaults.removeObjectForKey("lang")
                } else if index == 1 {
                    userDefaults.setObject("ENG", forKey: "lang")
                } else if index == 2 {
                    userDefaults.setObject("CHI", forKey: "lang")
                }
                
                userDefaults.synchronize()
                
                var reallang: String? = userDefaults.objectForKey("lang") as? String;
                
                if reallang == nil {
                    // reallang = NSLocale.preferredLanguages()[0] as! String == "zh" ? "CHI" : "ENG"
                    reallang = NSLocale.currentLocale().localeIdentifier.hasPrefix("zh") ? "CHI" : "ENG"
                }
                
                if reallang == "CHI" {
                    reallang = "zh-Hant"
                } else {
                    reallang = "en"
                }
                
                userDefaults.setObject([reallang!], forKey:"AppleLanguages")
                userDefaults.synchronize() //to make the change immediate
                
                NSBundle.setLanguage(reallang)
                
                IRecLibrary.clearSession()
                
                AppDelegate.getAppDelegate().window!.rootViewController=UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? UIViewController
            }
            
            alertController.addAction(UIAlertAction(title: "Auto", style: UIAlertActionStyle.Default, handler: callback))
            alertController.addAction(UIAlertAction(title: "English", style: UIAlertActionStyle.Default, handler: callback))
            alertController.addAction(UIAlertAction(title: "Chinese", style: UIAlertActionStyle.Default, handler: callback))
            alertController.addAction(UIAlertAction(title: "cancel".localized, style: UIAlertActionStyle.Cancel, handler: nil))
            
            
            self.presentViewController(alertController, animated: true, completion: nil)
        default:
            ()
        }
    }
    
    func cleanup() {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        
        fileManager.removeItemAtPath("~/Documents/alerts.plist".stringByExpandingTildeInPath, error: nil)
        fileManager.removeItemAtPath("~/Documents/recordings.plist".stringByExpandingTildeInPath, error: nil)
        fileManager.removeItemAtPath("~/Documents/history.plist".stringByExpandingTildeInPath, error: nil)
        fileManager.removeItemAtPath("~/Documents/favorites.bin".stringByExpandingTildeInPath, error: nil)
    }
    
}
