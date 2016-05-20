//
//  ProfileCollectionViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 23/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SpriteKit
import SwiftyUserDefaults

class ProfileCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, TransparentNavbarWithStatusBar ,TabControllerDelegate{
    
    private let queue = dispatch_queue_create("profile_collection_view", DISPATCH_QUEUE_SERIAL)
    
    private var profileViewModel: ProfileViewModel
    private var collectionViewModel: ProfileOptographsViewModel
    private var optographIDs: [UUID] = []
    
    weak var parentVC: UIViewController?
    
    private let editOverlayView = UIView()
    
    private let leftBarButton = UILabel()
    private let rightBarButton = UILabel()
    
    private var barButtonItem = UIBarButtonItem()
    let headerView = UIView()
    
    init(personID: UUID) {
        
        profileViewModel = ProfileViewModel(personID: personID)
        collectionViewModel = ProfileOptographsViewModel(personID: personID)
        
//        let textureSize = (getTextureWidth(UIScreen.mainScreen().bounds.width, hfov: HorizontalFieldOfView) - 4) / 3
//        imageCache = CollectionImageCache(textureSize: textureSize)
        
//        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        
        super.init(collectionViewLayout: UICollectionViewLeftAlignedLayout())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        headerView.frame = CGRect(x: 0,y: 0,width: view.frame.width ,height: 50)
        headerView.backgroundColor = UIColor(hex:0x3E3D3D)
        headerView.hidden = true
        view.addSubview(headerView)
        let texttext = UILabel()
        texttext.frame = CGRect(x: view.frame.width / 2 - (150/2),y: 15,width: 150,height: 20)
        texttext.text = "IAM360 Images"
        texttext.textAlignment = .Center
        texttext.textColor = UIColor.whiteColor()
        headerView.addSubview(texttext)
        
//        profileViewModel.userName.producer.startWithNext { [weak self] userName in
//            self?.title = userName.uppercaseString
//        }
        
        //originalBackButton = navigationItem.leftBarButtonItem
        
        tabController?.delegate = self
        
        title = "My Profile"
        var image = UIImage(named: "logo_small")
        image = image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: image, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(self.goToFeeds))
        
        leftBarButton.frame = CGRect(x: 0, y: -2, width: 21, height: 21)
        leftBarButton.text = String.iconWithName(.Cancel)
        leftBarButton.textColor = .whiteColor()
        leftBarButton.font = UIFont.iconOfSize(19)
        leftBarButton.userInteractionEnabled = true
        leftBarButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileCollectionViewController.tapLeftBarButton)))
        barButtonItem = UIBarButtonItem(customView: leftBarButton)
        
        profileViewModel.isEditing.producer.startWithNext { [weak self] isEditing in
            
            if isEditing {
                self?.navigationItem.leftBarButtonItem = self!.barButtonItem
            }
            //self?.navigationItem.leftBarButtonItem = isEditing ? self!.barButtonItem : self?.originalBackButton
        }
        
        rightBarButton.frame = CGRect(x: 0, y: -2, width: 21, height: 21)
        rightBarButton.rac_text <~ profileViewModel.isEditing.producer.mapToTuple(String.iconWithName(.Check), String.iconWithName(.More))
        rightBarButton.font = UIFont.iconOfSize(21)
        rightBarButton.userInteractionEnabled = true
        rightBarButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileCollectionViewController.tapRightBarButton)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightBarButton)
        
        editOverlayView.backgroundColor = UIColor.blackColor().alpha(0.6)
        editOverlayView.rac_hidden <~ profileViewModel.isEditing.producer.map(negate)
        view.addSubview(editOverlayView)
        
        profileViewModel.isEditing.producer.skip(1).startWithNext { [weak self] isEditing in
            if let strongSelf = self {
                
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                strongSelf.collectionView!.performBatchUpdates(nil, completion: { _ in CATransaction.commit() })
                
                if isEditing {
                    let collectionViewSize = strongSelf.collectionView!.frame.size
                    let textHeight = calcTextHeight(strongSelf.profileViewModel.text.value, withWidth: collectionViewSize.width - 28, andFont: UIFont.displayOfSize(12, withType: .Regular))
                    let headerHeight = 248 + textHeight
                    strongSelf.editOverlayView.frame = CGRect(x: 0, y: headerHeight, width: collectionViewSize.width, height: collectionViewSize.height - headerHeight)
                    
                    strongSelf.collectionView!.contentOffset = CGPointZero
                }
                
                strongSelf.collectionView!.scrollEnabled = !isEditing
            }
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        collectionView!.registerClass(ProfileHeaderCollectionViewCell.self, forCellWithReuseIdentifier: "top-cell")
        collectionView!.registerClass(ProfileTileCollectionViewCell.self, forCellWithReuseIdentifier: "tile-cell")
        
        collectionView!.backgroundColor = UIColor(hex:0xf7f7f7)
        
        collectionView!.alwaysBounceVertical = true
        
        collectionView!.delegate = self
        
//        collectionView!.pagingEnabled = true
        
//        automaticallyAdjustsScrollViewInsets = false
        
        collectionView!.delaysContentTouches = false
        
//        edgesForExtendedLayout = .None
        
        collectionViewModel.results.producer
            .filter {$0.changed}
            .delayAllUntil(collectionViewModel.isActive.producer)
            .observeOnMain()
            .on(next: { [weak self] results in
                if let strongSelf = self {
//                    let visibleOptographID: UUID? = strongSelf.optographIDs.isEmpty ? nil : strongSelf.optographIDs[strongSelf.collectionView!.indexPathsForVisibleItems().first!.row]
                    strongSelf.optographIDs = results.models.map { $0.ID }
                    
//                    CATransaction.begin()
//                    CATransaction.setDisableActions(true)
                        strongSelf.collectionView!.performBatchUpdates({
//                            strongSelf.imageCache.delete(results.delete)
//                            strongSelf.imageCache.insert(results.insert)
                            strongSelf.collectionView!.deleteItemsAtIndexPaths(results.delete.map { NSIndexPath(forItem: $0 + 1, inSection: 0) })
                            strongSelf.collectionView!.reloadItemsAtIndexPaths(results.update.map { NSIndexPath(forItem: $0 + 1, inSection: 0) })
                            strongSelf.collectionView!.insertItemsAtIndexPaths(results.insert.map { NSIndexPath(forItem: $0 + 1, inSection: 0) })
                        }, completion: { _ in
//                            if (!results.delete.isEmpty || !results.insert.isEmpty) && !strongSelf.refreshControl.refreshing {
//                                // preserves scroll position
//                                if let visibleOptographID = visibleOptographID, visibleRow = strongSelf.optographIDs.indexOf({ $0 == visibleOptographID }) {
//                                    strongSelf.collectionView!.contentOffset = CGPoint(x: 0, y: CGFloat(visibleRow) * strongSelf.view.frame.height)
//                                }
//                            }
//                            strongSelf.refreshControl.endRefreshing()
//                            CATransaction.commit()
                        })
                }
            })
            .start()
        
//        collectionViewModel.isActive.producer
//            .skip(1)
//            .map(negate)
//            .filter(identity)
//            .startWithNext { [weak self] _ in
//                self?.imageCache.reset()
//            }
    }
    
    deinit {
        logRetain()
    }
    func goToFeeds() {
        tabController!.leftButtonAction()
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetY:CGFloat  = scrollView.contentOffset.y
        //let contentHeight:CGFloat  = scrollView.contentSize.height;
        
//        if (offsetY >= 270) {
//            self.navigationController?.navigationItem.title = "IAM360 Images"
//            self.navigationController?.navigationBar.tintColor = UIColor(hex:0x575757)
//        } else {
//            self.navigationController?.navigationItem.title = "My Profile"
//            self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
//        }
        
        
        if (offsetY > 263) {
            UIView.animateWithDuration(0.5, animations: {
                self.headerView.hidden = false
                self.navigationController?.navigationBarHidden = true
                }, completion:nil)
        } else if  (offsetY < 263){
            UIView.animateWithDuration(0.5, animations: {
                self.headerView.hidden = true
                self.navigationController?.navigationBarHidden = false
                }, completion:nil)
        }
    }
    
    
    func reloadView() {
        collectionViewModel.refreshNotification.dispose()
        profileViewModel = ProfileViewModel(personID: SessionService.personID)
        collectionViewModel = ProfileOptographsViewModel(personID: SessionService.personID)
        
        rightBarButton.rac_text <~ profileViewModel.isEditing.producer.mapToTuple(String.iconWithName(.Check), String.iconWithName(.More))
        
        profileViewModel.isEditing.producer.startWithNext { [weak self] isEditing in
            if isEditing {
                self?.navigationItem.leftBarButtonItem = self!.barButtonItem
            }
            //self?.navigationItem.leftBarButtonItem = isEditing ? self!.barButtonItem : self?.originalBackButton
            
        }
        
        profileViewModel.isEditing.producer.skip(1).startWithNext { [weak self] isEditing in
            if let strongSelf = self {
                
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                strongSelf.collectionView!.performBatchUpdates(nil, completion: { _ in CATransaction.commit() })
                
                if isEditing {
                    let collectionViewSize = strongSelf.collectionView!.frame.size
                    let textHeight = calcTextHeight(strongSelf.profileViewModel.text.value, withWidth: collectionViewSize.width - 28, andFont: UIFont.displayOfSize(12, withType: .Regular))
                    let headerHeight = 248 + textHeight
                    strongSelf.editOverlayView.frame = CGRect(x: 0, y: headerHeight, width: collectionViewSize.width, height: collectionViewSize.height - headerHeight)
                    
                    strongSelf.collectionView!.contentOffset = CGPointZero
                }
                
                strongSelf.collectionView!.scrollEnabled = !isEditing
            }
        }
        
        collectionViewModel.results.producer
            .filter {$0.changed}
            .delayAllUntil(collectionViewModel.isActive.producer)
            .observeOnMain()
            .on(next: { [weak self] results in
                if let strongSelf = self {
                    strongSelf.optographIDs = results.models.map { $0.ID }
                    strongSelf.collectionView!.performBatchUpdates({
                        strongSelf.collectionView!.deleteItemsAtIndexPaths(results.delete.map { NSIndexPath(forItem: $0 + 1, inSection: 0) })
                        strongSelf.collectionView!.reloadItemsAtIndexPaths(results.update.map { NSIndexPath(forItem: $0 + 1, inSection: 0) })
                        strongSelf.collectionView!.insertItemsAtIndexPaths(results.insert.map { NSIndexPath(forItem: $0 + 1, inSection: 0) })
                        }, completion: { _ in
                    })
                }
                })
            .start()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (Defaults[.SessionNeedRefresh]) {
            self.reloadView()
            Defaults[.SessionNeedRefresh] = false
        }
        
        CoreMotionRotationSource.Instance.start()
        
        collectionViewModel.refreshNotification.notify(())
        collectionViewModel.isActive.value = true
        
//        view.bounds = UIScreen.mainScreen().bounds
        
//        RotationService.sharedInstance.rotationEnable()
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
//        RotationService.sharedInstance.rotationDisable()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        updateNavbarAppear()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        CoreMotionRotationSource.Instance.stop()
        
        collectionViewModel.isActive.value = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
//        view.frame = UIScreen.mainScreen().bounds
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return optographIDs.count + 1
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("top-cell", forIndexPath: indexPath) as! ProfileHeaderCollectionViewCell
            
            cell.bindViewModel(profileViewModel)
            cell.navigationController = navigationController as? NavigationController
            cell.parentViewController = self
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("tile-cell", forIndexPath: indexPath) as! ProfileTileCollectionViewCell
            
            let optographID = optographIDs[indexPath.item - 1]
            cell.bind(optographID)
            cell.backgroundColor = UIColor.blackColor()
            
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if indexPath.item == 0 {
            let textHeight = calcTextHeight(profileViewModel.text.value, withWidth: collectionView.frame.width - 28, andFont: UIFont.displayOfSize(12, withType: .Regular))
            //return CGSize(width: self.view.frame.width, height: 248 + textHeight)
            return CGSize(width: self.view.frame.width, height: 270 + textHeight)
        } else {
            let width = (self.view.frame.size.width)
            return CGSize(width: width, height: width)
        }
    }
    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
//        return UIEdgeInsetsMake(0, 100, self.view.frame.width, 0)
//    }
    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.item == 0 {
            
        } else {
//            let cell = cell as! TileCollectionViewCell
//            let optographID = optographIDs[indexPath.item - 1]
        }
        
//        guard let cell = cell as? CollectionViewCell else {
//            return
//        }
//        
//        let optographID = optographIDs[indexPath.item]
//        let optograph = Models.optographs[optographID]!.model
//        
//        cell.willDisplay((phi: Float(optograph.directionPhi), theta: Float(optograph.directionTheta)))
//        
//        print("will disp \(indexPath.item)")
//        
//        let imageCallback = { [weak self] (image: SKTexture, index: CubeImageCache.Index) in
//            if self?.collectionView?.indexPathsForVisibleItems().contains(indexPath) == true {
//                cell.setImage(image, forIndex: index)
//            }
//        }
//        
//        dispatch_async(queue) { [weak self] in
//            let defaultIndices = [
//                CubeImageCache.Index(face: 0, x: 0, y: 0, d: 1),
//                CubeImageCache.Index(face: 1, x: 0, y: 0, d: 1),
//                CubeImageCache.Index(face: 2, x: 0, y: 0, d: 1),
//                CubeImageCache.Index(face: 3, x: 0, y: 0, d: 1),
//                CubeImageCache.Index(face: 4, x: 0, y: 0, d: 1),
//                CubeImageCache.Index(face: 5, x: 0, y: 0, d: 1),
//            ]
//            self?.imageCache.get(indexPath.row, optographID: optographID, side: .Left, cubeIndices: defaultIndices, callback: imageCallback)
//        }
//        
//        if overlayView.optographID == nil {
//            overlayView.optographID = optographID
//        }
//        
////        cacheDebouncerTouch.debounce { [weak self] in
////            self?.imageCache.touch(indexPath.row)
////        }
//        
        
        if indexPath.item % 3 == 1 && indexPath.item > optographIDs.count - 7 {
            collectionViewModel.loadMoreNotification.notify(())
        }
        
    }
    
    override func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
//        (cell as! CollectionViewCell).didEndDisplay()
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        let profileOptographCollectionViewModel = ProfileOptographCollectionViewModel(personID: profileViewModel.personID, selectedOptographID: optographIDs[indexPath.item - 1])
//        let optographCollectionViewController = OptographCollectionViewController(viewModel: profileOptographCollectionViewModel)
//        navigationController!.pushViewController(optographCollectionViewController, animated: true)
        let detailsViewController = DetailsTableViewController(optographId: optographIDs[indexPath.item - 1])
        detailsViewController.cellIndexpath = indexPath.item
        navigationController?.pushViewController(detailsViewController, animated: true)
    }
    
    dynamic private func tapLeftBarButton() {
        profileViewModel.cancelEdit()
    }
    
    dynamic private func tapRightBarButton() {
        if profileViewModel.isEditing.value {
            profileViewModel.saveEdit()
        } else {
            let settingsSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            
            if profileViewModel.isMe {
                settingsSheet.addAction(UIAlertAction(title: "Sign out", style: .Destructive, handler: { _ in
                    SessionService.logoutReset()
                    SessionService.logout()
                }))
            } else {
                settingsSheet.addAction(UIAlertAction(title: "Report user", style: .Destructive, handler: { _ in
                    let confirmAlert = UIAlertController(title: "Are you sure?", message: "This action will message one of the moderators.", preferredStyle: .Alert)
                    confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
                    confirmAlert.addAction(UIAlertAction(title: "Report", style: .Destructive, handler: { _ in
                        //                    self.viewModel.person.report().start()
                    }))
                    self.navigationController?.presentViewController(confirmAlert, animated: true, completion: nil)
                }))
            }
            
            settingsSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
            
            navigationController?.presentViewController(settingsSheet, animated: true, completion: nil)
        }
    }
    
}

// MARK: - UITabBarControllerDelegate
extension ProfileCollectionViewController: DefaultTabControllerDelegate {
    
    func jumpToTop() {
        collectionViewModel.refreshNotification.notify(())
        collectionView!.setContentOffset(CGPointZero, animated: true)
    } 
}
