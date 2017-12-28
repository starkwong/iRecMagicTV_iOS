//
//  EditChannelsViewController.swift
//  iRecMagicTV
//
//  Created by Stark Wong on 2015/07/18.
//  Copyright (c) 2015年 Studio KUMA. All rights reserved.
//
// ♡♥

import UIKit

class EditChannelsTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var toggleButton: UIButton!
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let returnVal:UIView? = super.hitTest(point, withEvent: event)
        
        return (returnVal == nil ? nil : (returnVal! is UIButton ? titleLabel : nil))
    }
}

class EditChannelsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dttSwitch:UISwitch!
    @IBOutlet weak var nowSwitch:UISwitch!
    @IBOutlet weak var iCableSwitch:UISwitch!
    var items:[AnyObject]=[]
    var favorites:[String]=[]
    var channelMap:[String:AnyObject]=[:]
    var allChannels:[Channel]=[]
    
    override func viewDidLoad() {
        self.channelMap = ChannelViewController.generateChannelMap(allChannels)
        readFavorites()
        updateItems()
    }
    
    @IBAction func switchToggled(sender: UISwitch) {
        updateItems()
    }
    
    @IBAction func saveButtonPressed(sender: UIBarButtonItem) {
        saveFavorites()
    }
    
    func updateItems() {
        self.items.removeAll(keepCapacity: false)
        
        self.items.append(0)
        
        favorites.sort({ $0 < $1 })
        
        for favorite:String in favorites {
            self.items.append(self.channelMap[favorite]!)
        }
        
        self.items.append(1)
        
        for channel:Channel in allChannels {
            if find(favorites, channel.channelsel!) == nil {
                if count(channel.channelsel!) < 4 {
                    // DTT
                    if dttSwitch.on {
                        self.items.append(channel)
                    }
                } else if channel.channelsel!.hasPrefix("4") && nowSwitch.on {
                    self.items.append(channel)
                } else if channel.channelsel!.hasPrefix("8") && iCableSwitch.on {
                    self.items.append(channel)
                }
            }
        }
        
        self.tableView.reloadData()
    }
    
    func readFavorites() {
        self.favorites.removeAll(keepCapacity: false)
        
        let items:[String]? = NSKeyedUnarchiver.unarchiveObjectWithFile("~/Documents/favorites.bin".stringByExpandingTildeInPath) as? [String]
        
        if items != nil {
            self.favorites.extend(items!)
        }
    }
    
    func saveFavorites() {
        NSKeyedArchiver.archiveRootObject(self.favorites, toFile: "~/Documents/favorites.bin".stringByExpandingTildeInPath)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let item:AnyObject = self.items[indexPath.row]
        
        var cell:UITableViewCell?
        
        if item is Int {
            cell = tableView.dequeueReusableCellWithIdentifier((item as! Int == 0) ? "title_favorites" : "title_all", forIndexPath: indexPath) as? UITableViewCell
        } else {
            let cell2:EditChannelsTableViewCell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! EditChannelsTableViewCell
            
            cell=cell2
            
            let channel:Channel = item as! Channel
            
            cell2.titleLabel.text="\(channel.chnumber!) \(channel.chname)"
            cell2.subtitleLabel.text=channel.chlogo_alt
            //cell2.toggleButton.setTitle(find(self.favorites, channel.channelsel!) == nil ? "♡" : "♥", forState: UIControlState.Normal)
            
            cell2.toggleButton.selected = find(self.favorites, channel.channelsel!) != nil
            
        }
        
        return cell!
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("Click on \(indexPath)")
        
        let item:Channel = self.items[indexPath.row] as! Channel
        let cell:EditChannelsTableViewCell = tableView.cellForRowAtIndexPath(indexPath) as! EditChannelsTableViewCell
        
        if cell.toggleButton.selected {
            favorites.removeAtIndex(find(favorites, item.channelsel!)!)
        } else {
            favorites.append(item.channelsel!)
        }
        
        updateItems()
        self.tableView.reloadData()
    }
}
