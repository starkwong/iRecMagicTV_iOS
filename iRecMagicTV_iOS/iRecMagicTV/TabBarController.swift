//
//  TabBarControllerViewController.swift
//  iRecMagicTV
//
//  Created by Stark Wong on 2015/08/20.
//  Copyright (c) 2015年 Studio KUMA. All rights reserved.
//

import UIKit
import GoogleMobileAds

class TabBarController: UITabBarController {
    var bannerView:GADBannerView=GADBannerView(adSize:kGADAdSizeBanner)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        /*
        // 画面上部に標準サイズのビューを作成する
        // 利用可能な広告サイズの定数値は GADAdSize.h で説明されている
        bannerView = GADBannerView(adSize:kGADAdSizeBanner)
        
        // 広告ユニット ID を指定する
        bannerView.adUnitID = ""
        
        // ユーザーに広告を表示した場所に後で復元する UIViewController をランタイムに知らせて
        // ビュー階層に追加する
        bannerView.rootViewController = self
        self.view.addSubview(bannerView)
        self.tabBar.layoutMargins=UIEdgeInsets(top:50,left:0,bottom:50,right:0)
        println(self.tabBar.constraints)
        // 一般的なリクエストを行って広告を読み込む
        bannerView.loadRequest(GADRequest())
        
        var rect:CGRect=self.tabBar.frame
        rect.origin.y-=kGADAdSizeBanner.size.height
        self.tabBar.frame=rect*/
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

}
