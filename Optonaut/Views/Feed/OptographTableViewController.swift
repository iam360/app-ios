//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import PureLayout_iOS
import RealmSwift
import Alamofire
import SwiftyJSON
import Refresher

class OptographTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var items = [Optograph]()
    let tableView = UITableView()
    let navBarView = UINavigationBar()
    var navController: UINavigationController?
    
    var viewModel: OptographsTableViewModel
    
    required init(source: String, navController: UINavigationController?) {
        viewModel = OptographsTableViewModel(source: source)
        super.init(nibName: nil, bundle: nil)
        self.navController = navController
    }
    
    required init(coder aDecoder: NSCoder) {
        viewModel = OptographsTableViewModel(source: "")
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .None
        
        
        tableView.registerClass(OptographTableViewCell.self, forCellReuseIdentifier: "cell")
        
        tableView.addPullToRefreshWithAction {
            NSOperationQueue().addOperationWithBlock {
                self.viewModel.resultsLoading.put(true)
            }
        }
        
        viewModel.results.producer.start(
            next: { results in
                self.items = results
                self.tableView.reloadData()
                self.tableView.stopPullToRefresh()
            },
            error: { _ in
                self.tableView.stopPullToRefresh()
        })
        
        viewModel.resultsLoading.put(true)
        
        view.addSubview(tableView)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        
        super.updateViewConstraints()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let textString = (items[indexPath.row].text + items[indexPath.row].user!.userName) as NSString
        let textBounds = textString.sizeWithAttributes([NSFontAttributeName: UIFont.systemFontOfSize(17)])
        let numberOfLines = ceil(textBounds.width / (view.frame.width - 30))
        return view.frame.width + 70 + numberOfLines * 28
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! OptographTableViewCell
        cell.bindViewModel(items[indexPath.row])
        
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}


