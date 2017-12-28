//
//  ProgrammeItemTableViewCell.swift
//  iRecMagicTV
//
//  Created by Stark Wong on 2015/04/25.
//  Copyright (c) 2015年 Studio KUMA. All rights reserved.
//

import UIKit

class ProgrammeItemTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var recButton: UIButton!
    @IBOutlet weak var altButton: UIButton!
    
    var _item: AnyObject? = nil
    
    var item: AnyObject? {
        get {
            return _item
        }
        
        set (newItem) {
            _item = newItem
            
            if newItem is Channel {
                let channel: Channel = newItem as! Channel
                self.titleLabel.text = "\(channel.chnumber!) \(channel.chname)"
                self.subtitleLabel.text = channel.chlogo_alt
            } else if newItem is Programme {
                let programme: Programme = newItem as! Programme
                self.titleLabel.text = programme.progname
                self.subtitleLabel.text = "\(programme.progday) \(programme.progtime)"
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
