//
//  AlarmsViewController.swift
//  iRecMagicTV
//
//  Created by Stark Wong on 2015/04/25.
//  Copyright (c) 2015年 Studio KUMA. All rights reserved.
//

import UIKit

class AlarmsViewController: UITableViewController {
    // @IBOutlet weak var tableView: UITableView!
    var alerts: Array<Programme> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func readAlerts() -> Void {
        var flushed: Bool = false
        
        let timestamp: NSTimeInterval = NSDate().timeIntervalSince1970
        let timezone: NSTimeZone = NSTimeZone(name: "Asia/Hong_Kong")!
        
        alerts.removeAll(keepCapacity: false)
        
        for c2 in 0...1 {
            let jsonArray: Array<Dictionary<String,AnyObject>>? = NSKeyedUnarchiver.unarchiveObjectWithFile("~/Documents/alerts.plist".stringByExpandingTildeInPath) as? Array<Dictionary<String, AnyObject>>
            
            if jsonArray != nil {
                for jsonElement: Dictionary<String,AnyObject> in jsonArray! {
                    let programme: Programme = Programme(jsonObject: jsonElement)
                    
                    if c2 == 0 {
                        if programme.multi == false && programme.timestamp < timestamp {
                            flushed = true
                        } else {
                            self.alerts.append(programme)
                        }
                    }
                }
            }
        }
        
        if flushed {
            // alerts changed
            var array:Array<Dictionary<String,AnyObject>> = []
            
            for recording:Programme in self.alerts {
                array.append(recording.toJSONObject())
            }
            
            NSKeyedArchiver.archiveRootObject(array, toFile: "~/Documents/alerts.plist")
        }
        
        self.tableView.reloadData()
    }
    
    // MARK: View Action
    
    override func viewWillAppear(animated: Bool) {
        self.readAlerts()
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.alerts.count
    }
override     
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! UITableViewCell
        let programme:Programme = self.alerts[indexPath.row]
        
        cell.textLabel!.text = programme.progname
        cell.detailTextLabel!.text = "\(programme.progday) \(programme.progtime) " + (programme.multi ? "plf_multiple".localized : "plf_single".localized)
        cell.textLabel!.textColor = (indexPath.row < self.alerts.count ? UIColor.blackColor() : UIColor.lightGrayColor())
        
        return cell
    }
    
    // MARK: UITableViewDeleoverride gate
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
override     
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let programme:Programme = self.alerts[indexPath.row]
            let json:Dictionary<String,AnyObject> = programme.toJSONObject()
            
            for localNotification: UILocalNotification in UIApplication.sharedApplication().scheduledLocalNotifications as! Array<UILocalNotification> {
                if (localNotification.userInfo! as! Dictionary<String,AnyObject>)["href"]! as! String == json["href"] as! String {
                    UIApplication.sharedApplication().cancelLocalNotification(localNotification)
                    break
                }
            }
            
            var index:Array.Index? = find(alerts, programme)
            if index != nil { alerts.removeAtIndex(index!) }
            
            var array:Array<Dictionary<String,AnyObject>> = []
            
            for recording:Programme in self.alerts {
                array.append(recording.toJSONObject())
            }
            
            NSKeyedArchiver.archiveRootObject(array, toFile: "~/Documents/alerts.plist")
            
            self.tableView.reloadData()
        }
    }
}
