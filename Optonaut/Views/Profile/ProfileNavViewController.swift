//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

class ProfileNavViewController: UINavigationController {
    
    required init() {
        super.init(nibName: nil, bundle: nil)
        styleTabBarItem(tabBarItem, .User)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.translucent = true
        navigationBar.setBackgroundImage(UIImage(), forBarMetrics:UIBarMetrics.Default)
        navigationBar.shadowImage = UIImage()
        navigationBar.tintColor = .whiteColor() // needed for back button on details
        
        let userId = NSUserDefaults.standardUserDefaults().integerForKey(UserDefaultsKeys.UserId.rawValue);
        let profileVC = ProfileViewController(userId: userId)
        
//        let signoutButton = UIBarButtonItem()
//        let attributes = [NSFontAttributeName: UIFont.icomoonOfSize(20)]
//        signoutButton.setTitleTextAttributes(attributes, forState: .Normal)
//        signoutButton.title = String.icomoonWithName(.LogOut)
//        signoutButton.tintColor = .whiteColor()
//        signoutButton.target = self
//        signoutButton.action = "logout"
//        profileVC.navigationItem.setRightBarButtonItem(signoutButton, animated: false)
        
        pushViewController(profileVC, animated: false)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func logout() {
        let refreshAlert = UIAlertController(title: "You're about to log out...", message: "Really? Are you sure?", preferredStyle: UIAlertControllerStyle.Alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Sign out", style: .Default, handler: { (action: UIAlertAction!) in
            NSNotificationCenter.defaultCenter().postNotificationName(NotificationKeys.Logout.rawValue, object: nil)
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { _ in return }))
        
        presentViewController(refreshAlert, animated: true, completion: nil)
    }
    
}

