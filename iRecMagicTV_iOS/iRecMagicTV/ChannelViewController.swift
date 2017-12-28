//
//  ChannelViewController.swift
//  iRecMagicTV
//
//  Created by Stark Wong on 2015/05/14.
//  Copyright (c) 2015年 Studio KUMA. All rights reserved.
//

import UIKit
import GoogleMobileAds

class ChannelViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate {
    var channels: Array<Channel>? = nil
    var filteredChanels: [AnyObject]? = nil
    var showAllChannels: Bool = false
    // var bannerView: GADBannerView? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "MER"
        
        self.fetchData()
        
        /*
        // 画面上部に標準サイズのビューを作成する
        // 利用可能な広告サイズの定数値は GADAdSize.h で説明されている
        bannerView = GADBannerView(adSize:kGADAdSizeBanner)
        
        // 広告ユニット ID を指定する
        bannerView.adUnitID = "ca-app-pub-3533980603710847/1033082275"
        
        // ユーザーに広告を表示した場所に後で復元する UIViewController をランタイムに知らせて
        // ビュー階層に追加する
        bannerView.rootViewController = self
        self.view.addSubview(bannerView)
        
        // 一般的なリクエストを行って広告を読み込む
        bannerView.loadRequest(GADRequest())*/
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.channels != nil {
            self.filterFavorites()
        }
    }
    
    private func fetchData() {
        AppDelegate.getAppDelegate().iRecLibrary.getChannelList({ (objectType, result) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if objectType == IRecLibrary.ObjectType.CHANNELS {
                    println("channels received")
                    self.channels = result as? Array<Channel>
                    self.filterFavorites()
                    //self.tableView.reloadData()
                    let userDefaults: NSUserDefaults = NSUserDefaults()
                    var device: String? = userDefaults.objectForKey("device") as? String
                    
                    if device == nil { device = "-" }
                    
                    self.navigationItem.title = "MER [\(device!)]"
                } else {
                    let alertController: UIAlertController = UIAlertController(title: "clf_login_title".localized, message: nil, preferredStyle: UIAlertControllerStyle.Alert)
                    alertController.addTextFieldWithConfigurationHandler({ (textField) -> Void in
                        textField.placeholder="login_alert_mobileno".localized
                        textField.keyboardType=UIKeyboardType.NumberPad
                    })
                    alertController.addTextFieldWithConfigurationHandler({ (textField) -> Void in
                        textField.placeholder="login_alert_password".localized
                        textField.keyboardType=UIKeyboardType.NumberPad
                        textField.secureTextEntry=true;
                    })
                    alertController.addAction(UIAlertAction(title: "ok".localized, style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                        IRecLibrary.setLoginDetails((alertController.textFields![0] as! UITextField).text, password: (alertController.textFields![1] as! UITextField).text)
                        self.fetchData()
                    }))
                    alertController.addAction(UIAlertAction(title: "cancel".localized, style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                        self.fetchData()
                    }))
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
            })
        })
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredChanels == nil ? 0 : self.filteredChanels!.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let item: AnyObject! = self.filteredChanels![indexPath.row]
        
        if item is Channel {
            let cell: ProgrammeItemTableViewCell = tableView.dequeueReusableCellWithIdentifier("channel_item", forIndexPath: indexPath) as! ProgrammeItemTableViewCell
            
            cell.item = self.filteredChanels![indexPath.row]
            
            return cell
        } else {
            let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(item as! String, forIndexPath: indexPath) as! UITableViewCell
            
            if cell.tag == 1 {
                cell.textLabel!.text = self.showAllChannels ? "clf_show_favorites".localized : "clf_show_all".localized
            }
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell:UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        
        if cell.reuseIdentifier != nil && cell.reuseIdentifier! == "clf_show_all" {
            self.showAllChannels = !self.showAllChannels
            self.filterFavorites()
            self.tableView.reloadData()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier != nil {
            if segue.identifier! == "schedule" {
                let channel:Channel = self.filteredChanels![self.tableView.indexPathForCell(sender as! UITableViewCell)!.row] as! Channel
                let viewController: ScheduleViewController = segue.destinationViewController as! ScheduleViewController
                viewController.channel = channel
            } else if segue.destinationViewController is EditChannelsViewController {
                let viewController: EditChannelsViewController = segue.destinationViewController as! EditChannelsViewController
                viewController.allChannels = self.channels!
            }
        }
    }
    
    static func generateChannelMap(allChannels: [Channel]) -> [String: Channel] {
        var channelMap: [String: Channel] = [:]
        
        for channel: Channel in allChannels {
            channelMap[channel.channelsel!] = channel
        }
        
        return channelMap
    }
    
    func filterFavorites() -> Void {
        var channels: [AnyObject] = []
        
        if !self.showAllChannels {
            var jsonArray: [String]? = NSKeyedUnarchiver.unarchiveObjectWithFile("~/Documents/favorites.bin".stringByExpandingTildeInPath) as? [String]
            
            if jsonArray != nil {
                var favorites: [String] = []
                let channelMap = ChannelViewController.generateChannelMap(self.channels!)
                var channel: Channel?
                
                for jsonItem: String in jsonArray! {
                    channel = channelMap[jsonItem]
                    if channel != nil {
                        channels.append(channel!)
                    }
                }
                
                channels.append("clf_show_all")
                channels.append("clf_edit_favorites")
            }
        }
        
        if channels.count == 0 {
            if !self.showAllChannels {
                channels.append("clf_create_favorites")
            } else {
                channels.append("clf_show_all") // clf_show_favorites
                channels.append("clf_edit_favorites")
            }
            
            for channel: Channel in self.channels! {
                channels.append(channel)
            }
        }
        
        self.filteredChanels = channels
        
        self.tableView.reloadData()
    }
}
