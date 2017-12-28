//
//  RecordingsViewController.swift
//  iRecMagicTV
//
//  Created by Stark Wong on 2015/04/25.
//  Copyright (c) 2015年 Studio KUMA. All rights reserved.
//

import UIKit

class RecordingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    var recordings: Array<Programme> = []
    var histories: Array<Programme> = []
    var fulllist: Array<Programme> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        (self.view.viewWithTag(1) as! UITextView).text="rvc_note".localized
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func readRecordings() -> Void {
        var moved: Bool = false
        var flushed: Bool = false
        
        let timestamp: NSTimeInterval = NSDate().timeIntervalSince1970
        let timezone: NSTimeZone = NSTimeZone(name: "Asia/Hong_Kong")!
        
        recordings.removeAll(keepCapacity: false)
        histories.removeAll(keepCapacity: false)
        fulllist.removeAll(keepCapacity: false)

        for c2 in 0...1 {
            let jsonArray: Array<Dictionary<String,AnyObject>>? = NSKeyedUnarchiver.unarchiveObjectWithFile((c2==0 ? "~/Documents/recordings.plist" : "~/Documents/history.plist").stringByExpandingTildeInPath) as? Array<Dictionary<String, AnyObject>>
            
            if jsonArray != nil {
                for jsonElement: Dictionary<String,AnyObject> in jsonArray! {
                    let programme: Programme = Programme(jsonObject: jsonElement)
                    
                    if c2 == 0 {
                        if programme.multi == false && programme.timestamp < timestamp {
                            self.histories.append(programme)
                            flushed = true
                            moved = true
                        } else {
                            self.recordings.append(programme)
                        }
                        self.fulllist.append(programme)
                    } else {
                        if timestamp - programme.timestamp < Double(1000 * 60 * 60 * 24 * 14) {
                            // Less than 14 days
                            self.histories.append(programme)
                            self.fulllist.append(programme)
                        } else {
                            println("readRecording(): Item expired: \(programme.progname) (\(programme.timestamp)")
                            flushed = true
                        }
                    }
                }
            }
        }
        
        println("readRecording(): moved=\(moved) flushed=\(flushed)")
        
        if moved {
            // recordings changed
            var c:Int = 0
            
            for list:Array<Programme> in [self.recordings,self.histories] {
                var array:Array<Dictionary<String,AnyObject>> = []
                
                for recording:Programme in list {
                    array.append(recording.toJSONObject())
                }
                
                NSKeyedArchiver.archiveRootObject(array, toFile: (c == 0 ? "~/Documents/recordings.plist" : "~/Documents/history.plist"))
                
                c++
                
                if !flushed { break; }
            }
            
        }
        
        self.fulllist.sort { (left: Programme, right: Programme) -> Bool in
            // is_ordered_before
            return left.timestamp > right.timestamp;
        }
        
        self.tableView.reloadData()
    }
    
    // MARK: View Action
    
    override func viewWillAppear(animated: Bool) {
        self.readRecordings()
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fulllist.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! UITableViewCell
        let programme:Programme = self.fulllist[indexPath.row]
        
        cell.textLabel!.text = programme.progname
        cell.detailTextLabel!.text = "\(programme.progday) \(programme.progtime) " + (programme.multi ? "plf_multiple".localized : "plf_single".localized)
        cell.textLabel!.textColor = (indexPath.row < self.recordings.count ? UIColor.blackColor() : UIColor.lightGrayColor())

        return cell
    }
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let programme:Programme = self.fulllist[indexPath.row]
            
            var index:Array.Index? = find(recordings, programme)
            if index != nil { recordings.removeAtIndex(index!) }
            
            index = find(histories, programme)
            if index != nil { histories.removeAtIndex(index!) }
            
            var c:Int = 0
            
            for list:Array<Programme> in [self.recordings,self.histories] {
                var array:Array<Dictionary<String,AnyObject>> = []
                
                for recording:Programme in list {
                    array.append(recording.toJSONObject())
                }
                
                NSKeyedArchiver.archiveRootObject(array, toFile: (c == 0 ? "~/Documents/recordings.plist" : "~/Documents/history.plist"))
                
                c++
            }
            
            self.fulllist.removeAll(keepCapacity: true)
            self.fulllist.extend(recordings)
            self.fulllist.extend(histories)
            
            self.tableView.reloadData()
        }
    }
}

