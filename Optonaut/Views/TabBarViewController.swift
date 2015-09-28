//
//  TabBarViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import SQLite

class TabBarViewController: UITabBarController {
    
    let feedNavViewController = FeedNavViewController()
    let exploreNavViewController = ExploreNavViewController()
//    let activityNavViewController = ActivityNavViewController()
    let profileNavViewController = ProfileNavViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set view controllers
        viewControllers = [
            feedNavViewController,
            exploreNavViewController,
//            activityNavViewController,
            profileNavViewController
        ]
        
        feedNavViewController.initNotificationIndicator()
//        activityNavViewController.initNotificationIndicator()
        
        // set bar color
        tabBar.barTintColor = UIColor.Accent
        tabBar.translucent = false
        
        // set font for bar items
        let tabBarItemAppearance = UITabBarItem.appearance()
        let attribues = [
            NSFontAttributeName: UIFont.icomoonOfSize(22),
            NSForegroundColorAttributeName: UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        ]
        tabBarItemAppearance.setTitleTextAttributes(attribues, forState: .Normal)
        tabBarItemAppearance.titlePositionAdjustment = UIOffsetMake(0, -12)
        
        // set darker red as selected background color
        let numberOfItems = CGFloat(tabBar.items!.count)
        let tabBarItemSize = CGSize(width: tabBar.frame.width / numberOfItems, height: tabBar.frame.height)
        tabBar.selectionIndicatorImage = UIImage.imageWithColor(UIColor(0xc93c2f), size: tabBarItemSize).resizableImageWithCapInsets(UIEdgeInsetsZero)
        
        // remove default border
        tabBar.frame.size.width = self.view.frame.width + 4
        tabBar.frame.origin.x = -2
    }
    
}