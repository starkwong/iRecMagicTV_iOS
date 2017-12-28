//
//  ScheduleViewController.swift
//  iRecMagicTV
//
//  Created by Stark Wong on 2015/04/25.
//  Copyright (c) 2015年 Studio KUMA. All rights reserved.
//

import UIKit

class ScheduleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    var channel: Channel? = nil
    var items: Array<Programme>? = nil
    var filteredItems: Array<Programme>? = nil
    var initialDoW: Bool?
    var recordings: Array<String> = []
    var alerts: Array<String> = []
    var lastHref: String? = nil
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: UIView!
    weak var currentDoW: UIButton?
    
    // MARK: Private functions
    func cellOfView(button: UIButton) -> UITableViewCell? {
        var parentView: UIView? = button
        
        while parentView != nil && !(parentView! is UITableViewCell) {
            parentView = parentView!.superview
        }
        
        return (parentView != nil && parentView! is UITableViewCell) ? (parentView as? UITableViewCell) : nil
    }
    
    func readStorage() -> Void {
        var records: Array<Dictionary<String, AnyObject>>?
        
        records = NSKeyedUnarchiver.unarchiveObjectWithFile("~/Documents/recordings.plist".stringByExpandingTildeInPath) as? Array<Dictionary<String, AnyObject>>
        
        recordings.removeAll(keepCapacity: true)
        
        if records != nil {
            for record: Dictionary<String, AnyObject> in records! {
                recordings.append(record["href"]! as! String)
            }
        }
        
        records = NSKeyedUnarchiver.unarchiveObjectWithFile("~/Documents/alerts.plist".stringByExpandingTildeInPath) as? Array<Dictionary<String, AnyObject>>
        
        alerts.removeAll(keepCapacity: true)
        
        if records != nil {
            for record: Dictionary<String, AnyObject> in records! {
                alerts.append(record["href"]! as! String)
            }
        }
        
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        AppDelegate.getAppDelegate().iRecLibrary.getProgrammeList(self.channel!.href, callback: { (objectType, result) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if objectType == IRecLibrary.ObjectType.PROGRAMMES {
                    println("programmes list received")
                    self.readStorage()
                    
                    self.items = result as? Array<Programme>
                    self.initialDoW = true
                    // self.tableView.reloadData()
                    
                    let calendar: NSCalendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
                    let dow: Int = calendar.component(NSCalendarUnit.CalendarUnitWeekday, fromDate: NSDate())
                    let button: UIButton = self.headerView.viewWithTag(dow)! as! UIButton
                    button.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                }
            })
        })
        
        self.navigationItem.title="\(channel!.chnumber!) \(channel!.chname)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: View actions
    @IBAction func dowButtonPressed(sender: UIButton) {
        self.currentDoW = sender
        
        for button: UIButton in self.headerView.subviews as! Array<UIButton> {
            button.backgroundColor = button == sender ? UIColor.lightGrayColor() : UIColor.clearColor()
        }
        
        var programmes: Array<Programme> = []
        let criteria: String = ["","Sun","Mon","Tue","Wed","Thu","Fri","Sat"][sender.tag]
        
        var initialSelect: Int = -1
        var index: Int = 0
        
        let currentTime: NSTimeInterval = NSDate().timeIntervalSince1970
        // let timezone: NSTimeZone = NSTimeZone(name: "Asia/Hong_Kong")!
        
        for programme: Programme in self.items! {
            if programme.name! == criteria {
                programmes.append(programme)
                if programme.timestamp /* + Double(timezone.secondsFromGMT) */ <= currentTime {
                    initialSelect = index
                }
                index++
            }
        }
        
        self.filteredItems = programmes
        self.tableView.reloadData()
        
        if self.initialDoW! {
            self.initialDoW = false
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: initialSelect, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
        }
    }
    
    @IBAction func recButtonPressed(sender: UIButton) {
        let cell: UITableViewCell? = self.cellOfView(sender)
        
        if cell == nil {
            println("Cell not found!")
        } else {
            let indexPath: NSIndexPath? = self.tableView.indexPathForCell(cell!)
            println("Cell found! index is \(indexPath!.row)")
            
            let currentProgramme: Programme = self.filteredItems![indexPath!.row]
            
            let recordings: Array<Dictionary<String, AnyObject>>? = NSKeyedUnarchiver.unarchiveObjectWithFile("~/Documents/recordings.plist".stringByExpandingTildeInPath) as? Array<Dictionary<String, AnyObject>>
            
            if recordings != nil {
                for recording: Dictionary<String, AnyObject> in recordings! {
                    let programme: Programme = Programme(jsonObject: recording)
                    
                    if programme.duration > 0 && (currentProgramme.timestamp >= programme.timestamp && Int(currentProgramme.timestamp) < (Int(programme.timestamp) + programme.duration) || (Int(currentProgramme.timestamp) + currentProgramme.duration) < Int(programme.timestamp) && (Int(currentProgramme.timestamp) + currentProgramme.duration) >= (Int(programme.timestamp) + programme.duration)) {
                        var channel: String? = recording["channel"] as? String
                        if channel == nil { channel = "" }
                        
                        UIAlertView(title: "plf_exist_title".localized, message: "plf_overlap".localized + channel! /*"The current programme overlaps with a scheduled programme:\n\(channel!)"*/, delegate: nil, cancelButtonTitle: "ok".localized).show()
                        
                    }
                }
            }
            
            let recordFunc = { (alertAction: UIAlertAction!) -> Void in
                var callback2: ((IRecLibrary.ObjectType, AnyObject?) -> Void)? = nil
                
                let genericUrlCallback: (IRecLibrary.ObjectType, AnyObject?) -> Void = { (objectType: IRecLibrary.ObjectType, result: AnyObject?) -> Void in
                    if objectType == IRecLibrary.ObjectType.HREF {
                        println("performGenericURL: result=\(result)")
                        
                        let info: Array<String> = (result as! Array<Array<AnyObject>>)[0] as! Array<String>
                        let hrefs: Array<Href> = (result as! Array<Array<AnyObject>>)[1] as! Array<Href>
                        
                        var durationText: String = "NA"
                        
                        if (currentProgramme.duration != 0) {
                            let minutes: Int = currentProgramme.duration / 60
                            
                            durationText = NSString(format: "%d:%02d", minutes / 60, minutes % 60) as! String
                        }
                        
                        let alertController: UIAlertController = UIAlertController(title: "plf_info_title".localized, message: String(format: "plf_info_prerecord".localized, info[0], info[1], durationText, info[2], info[3]) , preferredStyle: UIAlertControllerStyle.ActionSheet)
                        
                        var actions: Array<UIAlertAction> = []
                        
                        let handler = { (alertAction: UIAlertAction!) -> Void in
                            let index: Array.Index = find(actions, alertAction)!
                            let href: Href = hrefs[index]
                            
                            self.lastHref = href.href
                            IRecLibrary.sharedInstance().performGenericURL(href.href, callback: callback2!)
                        }
                        
                        for href: Href in hrefs {
                            let alertAction: UIAlertAction = UIAlertAction(title: href.title, style: UIAlertActionStyle.Default, handler: handler)
                            
                            alertController.addAction(alertAction)
                            actions.append(alertAction)
                        }
                        
                        alertController.addAction(UIAlertAction(title: "cancel".localized, style: UIAlertActionStyle.Cancel, handler: nil))
                        self.presentViewController(alertController, animated: true, completion: nil)
                    } else if objectType == IRecLibrary.ObjectType.EMPTY {
                        // Successful
                        println("performGenericURL: successful")
                        
                        // Success
                        var records: Array<Dictionary<String, AnyObject>>? = NSKeyedUnarchiver.unarchiveObjectWithFile("~/Documents/recordings.plist".stringByExpandingTildeInPath) as? Array<Dictionary<String, AnyObject>>
                        
                        if records == nil { records = [] }
                        
                        let channelUrl: String = currentProgramme.href
                        let channel: String = channelUrl.substringFromIndex(advance(channelUrl.rangeOfString("=")!.startIndex, 1))
                        let title: String = self.navigationItem.title!
                        
                        var dict: Dictionary<String,AnyObject> = currentProgramme.toJSONObject()
                        dict["channel"] = channel
                        dict["channeltitle"] = title
                        dict["duration"] = currentProgramme.duration
                        dict["single"] = self.lastHref!.rangeOfString("presingleRec.php") != nil
                        
                        records!.append(dict)

                        NSKeyedArchiver.archivedDataWithRootObject(records!).writeToFile("~/Documents/recordings.plist".stringByExpandingTildeInPath, atomically: true)
                        
                        UIAlertView(title: "plf_info_title".localized, message: "plf_success_mesage".localized, delegate: nil, cancelButtonTitle: "ok".localized).show()
                        
                        self.readStorage()
                        self.tableView.reloadData()
                    }
                }
                callback2 = genericUrlCallback
                IRecLibrary.sharedInstance().performGenericURL(currentProgramme.href, callback: genericUrlCallback)
            }
                
            let okAction: UIAlertAction = UIAlertAction(title: "yes".localized, style: UIAlertActionStyle.Default, handler: recordFunc)
            
            if contains(self.recordings, currentProgramme.href) {
                let alertController: UIAlertController = UIAlertController(title: "plf_exist_title".localized, message: "plf_exist_message".localized, preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "no".localized, style: UIAlertActionStyle.Cancel, handler: nil))
                alertController.addAction(okAction)
                self.presentViewController(alertController, animated: true, completion: nil)
            } else {
                recordFunc(okAction)
            }
            
            // TODO
            /*
            if (recordings.contains(programme.href)) {
                new AlertDialog.Builder(getContext())
                .setTitle(R.string.plf_exist_title)
                .setMessage(R.string.plf_exist_message)
                .setPositiveButton(R.string.yes, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialogInterface, int i) {
                        currentProgramme = programme;
                        forRecording = true;
                        ProgressIndicator.showIndicator(getActivity());
                        getMainActivity().iRecLibrary.prepareForRecording(programme.href, ProgrammeListFragment.this);
                    }
                    }).setNegativeButton(R.string.no, null)
                        .setIcon(android.R.drawable.ic_dialog_alert)
                        .show();
            } else {
                currentProgramme = programme;
                forRecording = true;
                //getMainActivity().iRecLibrary.prepareForRecording(programme.href, ProgrammeListFragment.this);
                ProgressIndicator.showIndicator(getActivity());
                getMainActivity().iRecLibrary.performGenericURL(programme.href, ProgrammeListFragment.this);
            }*/
            
        }
    }
    
    @IBAction func altButtonPressed(sender: UIButton) {
        let cell: UITableViewCell? = self.cellOfView(sender)
        
        if cell == nil {
            println("Cell not found!")
        } else {
            let indexPath: NSIndexPath? = self.tableView.indexPathForCell(cell!)
            println("Cell found! index is \(indexPath!.row)")
            
            let currentProgramme: Programme = self.filteredItems![indexPath!.row]
            
            let recordings: Array<Dictionary<String, AnyObject>>? = NSKeyedUnarchiver.unarchiveObjectWithFile("~/Documents/recordings.plist".stringByExpandingTildeInPath) as? Array<Dictionary<String, AnyObject>>
            
            let recordFunc = { (alertAction: UIAlertAction!) -> Void in
                let localNotification: UILocalNotification = UILocalNotification()
                localNotification.fireDate = NSDate(timeIntervalSince1970: currentProgramme.timestamp)
                localNotification.alertBody = String(format: "aea_start".localized, currentProgramme.progname, self.channel!.chname)
                localNotification.soundName = UILocalNotificationDefaultSoundName
                localNotification.userInfo = currentProgramme.toJSONObject()
                
                UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
                
                var records: Array<Dictionary<String, AnyObject>>? = NSKeyedUnarchiver.unarchiveObjectWithFile("~/Documents/alerts.plist".stringByExpandingTildeInPath) as? Array<Dictionary<String, AnyObject>>
                
                if records == nil { records = [] }
                
                let channelUrl: String = currentProgramme.href
                let channel: String = channelUrl.substringFromIndex(advance(channelUrl.rangeOfString("=")!.startIndex, 1))
                let title: String = self.navigationItem.title!
                
                var dict: Dictionary<String,AnyObject> = currentProgramme.toJSONObject()
                dict["channel"] = channel
                dict["channeltitle"] = title
                dict["duration"] = currentProgramme.duration
                dict["single"] = true // self.lastHref!.rangeOfString("presingleRec.php") != nil
                
                records!.append(dict)
                
                NSKeyedArchiver.archivedDataWithRootObject(records!).writeToFile("~/Documents/alerts.plist".stringByExpandingTildeInPath, atomically: true)
                
                
                UIAlertView(title: "plf_exist2_title".localized, message: "plf_success2_message".localized, delegate: nil, cancelButtonTitle: "ok".localized).show()
            }
            
            let okAction: UIAlertAction = UIAlertAction(title: "yes".localized, style: UIAlertActionStyle.Default, handler: recordFunc)
            
            if contains(self.alerts, currentProgramme.href) {
                let alertController: UIAlertController = UIAlertController(title: "plf_exist_title".localized, message: "plf_exist_message".localized, preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "no".localized, style: UIAlertActionStyle.Cancel, handler: nil))
                alertController.addAction(okAction)
                self.presentViewController(alertController, animated: true, completion: nil)
            } else {
                recordFunc(okAction)
            }
        }
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredItems == nil ? 0 : filteredItems!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: ProgrammeItemTableViewCell = tableView.dequeueReusableCellWithIdentifier("programme_item", forIndexPath: indexPath) as! ProgrammeItemTableViewCell
        
        cell.item = self.filteredItems![indexPath.row]
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("Cell selected on row \(indexPath.row)")
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let currentProgramme: Programme = self.filteredItems![indexPath.row]
        
        AppDelegate.getAppDelegate().iRecLibrary.getProgrammeInfo(currentProgramme.href, callback: { (objectType, result) -> Void in
            if objectType == IRecLibrary.ObjectType.PROGRAMMEINFO {
                if result==nil || (result! as! Array<String>).count==0 {
                    UIAlertView(title: "plf_info_title".localized, message: "plf_info_error".localized, delegate: nil, cancelButtonTitle: "ok".localized).show()
                } else {
                    var durationText: String = "N/A"
                    
                    if (currentProgramme.duration != 0) {
                        let minutes: Int = currentProgramme.duration / 60
                        
                        durationText = NSString(format: "%d:%02d", minutes / 60, minutes % 60) as! String
                    }
                    
                    let info: Array<String> = result! as! Array<String>
                    
                    UIAlertView(title: "plf_info_title".localized, message: String(format: "plf_info_prerecord".localized, info[0], info[1], durationText, info[2], info[3]) , delegate: nil, cancelButtonTitle: "ok".localized).show()
                }
            }
        })
    }
    
    // MARK: UISearchBarDelegate
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        let enable: Bool = (count(searchText) == 0)
        
        self.headerView.userInteractionEnabled = enable
        
        if enable {
            filteredItems = items
            
            self.initialDoW = true
            
            let calendar: NSCalendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
            let dow: Int = calendar.component(NSCalendarUnit.CalendarUnitWeekday, fromDate: NSDate())
            let button: UIButton = self.headerView.viewWithTag(dow)! as! UIButton
            button.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
        } else {
            var programmes: [Programme] = []
            let criteria = searchText.lowercaseString
            
            if currentDoW != nil {
                currentDoW!.backgroundColor = UIColor.clearColor()
                currentDoW = nil
            }
            
            for programme: Programme in items! {
                if programme.progname.lowercaseString.rangeOfString(criteria) != nil || programme.progday.lowercaseString.hasPrefix(criteria) {
                    programmes.append(programme)
                }
            }
            
            filteredItems = programmes
        }
        
        self.tableView.reloadData()
    }
}

