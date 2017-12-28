//
//  LocalizedString.swift
//  iRecMagicTV
//
//  Created by Stark Wong on 2015/08/16.
//  Copyright (c) 2015年 Studio KUMA. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: "")
    }
}
