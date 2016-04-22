//
//  TabViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 24/12/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Async
import Icomoon
import SwiftyUserDefaults
import Result

class TabViewController: UIViewController,
                            UIImagePickerControllerDelegate,
                            UINavigationControllerDelegate{
    
    enum ActiveSide: Equatable { case Left, Right }
    
    private let uiWrapper = PassThroughView()
    
    var indicatedSide: ActiveSide? {
        didSet {
            updateIndicatedSide()
        }
    }
    
    private let indicatedSideLayer = CALayer()
    
    let cameraButton = RecordButton()
    let leftButton = TabButton()
    let rightButton = TabButton()
    let oneRingButton = UIButton()
    let threeRingButton = UIButton()
    
    private let bottomGradient = CAGradientLayer()
    
    let bottomGradientOffset = MutableProperty<CGFloat>(126)
    let isThetaImage = MutableProperty<Bool>(false)
    
    let leftViewController: NavigationController
    let rightViewController: NavigationController
    var activeViewController: NavigationController
    
    private var uiHidden = false
    private var uiLocked = false
    
    var delegate: TabControllerDelegate?
    
    var imageView: UIImageView!
    var imagePicker = UIImagePickerController()
    
    required init() {
        leftViewController = FeedNavViewController()
        rightViewController = ProfileNavViewController()
        
        activeViewController = leftViewController
        
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChildViewController(leftViewController)
        addChildViewController(rightViewController)
        
        view.insertSubview(leftViewController.view, atIndex: 0)
        indicatedSide = .Left
        //updateActiveTab(.Right)
        
        let width = view.frame.width
        
        bottomGradient.colors = [UIColor.clearColor().CGColor, UIColor.blackColor().alpha(0.5).CGColor]
        uiWrapper.layer.addSublayer(bottomGradient)
        
        indicatedSideLayer.backgroundColor = UIColor.Accent.CGColor
        indicatedSideLayer.cornerRadius = 5
        uiWrapper.layer.addSublayer(indicatedSideLayer)
        
        bottomGradientOffset.producer.startWithNext { [weak self] offset in
            CATransaction.begin()
            CATransaction.setDisableActions(true)
//            CATransaction.setAnimationDuration(0.3)
//            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
            self?.bottomGradient.frame = CGRect(x: 0, y: 0, width: width, height: offset)
            CATransaction.commit()
        }
        
        cameraButton.frame = CGRect(x: view.frame.width / 2 - 35, y: 126 / 2 - 35, width: 70, height: 70)
        cameraButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapCameraButton"))
        cameraButton.addTarget(self, action: "touchStartCameraButton", forControlEvents: [.TouchDown])
        cameraButton.addTarget(self, action: "touchEndCameraButton", forControlEvents: [.TouchUpInside, .TouchUpOutside, .TouchCancel])
        uiWrapper.addSubview(cameraButton)
        
        oneRingButton.frame = CGRect(x: cameraButton.frame.origin.x-35, y: cameraButton.frame.origin.y+23, width: 30, height: 30)
        oneRingButton.addTarget(self, action: "touchOneRingButton", forControlEvents: [.TouchDown])
        oneRingButton.setImage(UIImage(named: "oneRingButton"), forState: UIControlState.Normal)
        oneRingButton.layer.cornerRadius = 5
        uiWrapper.addSubview(oneRingButton)
        
        threeRingButton.frame = CGRect(x: cameraButton.frame.origin.x+cameraButton.frame.size.width+5, y: cameraButton.frame.origin.y+23, width: 30, height: 30)
        threeRingButton.addTarget(self, action: "touchThreeRingButton", forControlEvents: [.TouchDown])
        threeRingButton.setImage(UIImage(named: "threeRingButton"), forState: UIControlState.Normal)
        threeRingButton.layer.cornerRadius = 5
        uiWrapper.addSubview(threeRingButton)
        
        switch Defaults[.SessionUseMultiRing] {
        case true:
            threeRingButton.backgroundColor = UIColor(red: 0.94, green: 0.28, blue: 0.21, alpha: 0.9)
            oneRingButton.backgroundColor = UIColor.grayColor()
        case false:
            threeRingButton.backgroundColor = UIColor.grayColor()
            oneRingButton.backgroundColor = UIColor(red: 0.94, green: 0.28, blue: 0.21, alpha: 0.9)
        }
        
        PipelineService.stitchingStatus.producer
            .observeOnMain()
            .startWithNext { [weak self] status in
                switch status {
                case .Uninitialized:
                    self?.cameraButton.loading = true
                case .Idle:
                    self?.cameraButton.progress = nil
                    if self?.cameraButton.progressLocked == false {
                        self?.cameraButton.icon = .Camera
                        self?.rightButton.loading = false
                        self?.unhideRingButton()
                    }
                case let .Stitching(progress):
                    self?.cameraButton.progress = CGFloat(progress)
                case .StitchingFinished(_):
//                    self?.cameraButton.progress = 1
                    self?.cameraButton.progress = nil
                }
            }

        let buttonSpacing = (view.frame.width / 2 - 35) / 2 - 14
        leftButton.frame = CGRect(x: buttonSpacing, y: 126 / 2 - 23.5, width: 28, height: 28)
        leftButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapLeftButton"))
        uiWrapper.addSubview(leftButton)

        rightButton.frame = CGRect(x: view.frame.width - buttonSpacing - 28, y: 126 / 2 - 23.5, width: 28, height: 28)
        rightButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapRightButton"))
        uiWrapper.addSubview(rightButton)
        
        initNotificationIndicator()
        
        PipelineService.checkStitching()
        PipelineService.checkUploading()
        
        uiWrapper.frame = CGRect(x: 0, y: view.frame.height - 126, width: view.frame.width, height: 126)
        view.addSubview(uiWrapper)
        
        imagePicker.delegate = self
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        isThetaImage.producer
        .filter(isTrue)
            .startWithNext{ _ in
                let alert = UIAlertController(title: "Ooops!", message: "Not a Theta Image, Please choose another photo", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler:{ _ in
                    self.isThetaImage.value = false
                }))
                self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    func openGallary()
    {
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.navigationBar.translucent = false
        imagePicker.navigationBar.barTintColor = UIColor.Accent
        imagePicker.navigationBar.setTitleVerticalPositionAdjustment(0, forBarMetrics: .Default)
        imagePicker.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.displayOfSize(15, withType: .Semibold),
            NSForegroundColorAttributeName: UIColor.whiteColor(),
        ]
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .None)
        imagePicker.setNavigationBarHidden(false, animated: false)
        imagePicker.interactivePopGestureRecognizer?.enabled = false
        
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func uploadTheta(thetaImage:UIImage) {
        
        let createOptographViewController = SaveThetaViewController(thetaImage:thetaImage)
        
        createOptographViewController.hidesBottomBarWhenPushed = true
        activeViewController.pushViewController(createOptographViewController, animated: false)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            if pickedImage.size.height == 2688 && pickedImage.size.width == 5376 {
                uploadTheta(pickedImage)
            } else {
                isThetaImage.value = true
            }
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showUI() {
        if !uiLocked {
            uiWrapper.hidden = false
        }
    }
    
    func hideUI() {
        if !uiLocked {
            uiWrapper.hidden = true
        }
    }
    
    func lockUI() {
        uiLocked = true
    }
    
    func unlockUI() {
        uiLocked = false
    }
    func unhideRingButton() {
        oneRingButton.hidden = false
        threeRingButton.hidden = false
    }
    func hideRingButton() {
        oneRingButton.hidden = true
        threeRingButton.hidden = true
    }
    
    dynamic private func tapLeftButton() {
        delegate?.onTapLeftButton()
    }
    
    dynamic private func tapRightButton() {
        delegate?.onTapRightButton()
    }
    
    dynamic private func tapCameraButton() {
        delegate?.onTapCameraButton()
    }
    
    dynamic private func touchStartCameraButton() {
        delegate?.onTouchStartCameraButton()
    }
    dynamic private func touchOneRingButton() {
        delegate?.onTouchOneRingButton()
    }
    dynamic private func touchThreeRingButton() {
        delegate?.onTouchThreeRingButton()
    }
    
    dynamic private func touchEndCameraButton() {
        delegate?.onTouchEndCameraButton()
    }
    
    func updateActiveTab(side: ActiveSide) {
        let isLeft = side == .Left
        
        if !isLeft && !SessionService.isLoggedIn {
            hideUI()
            lockUI()
            
            let loginOverlayViewController = LoginOverlayViewController(
                title: "Login to save your moment",
                successCallback: {
                    self.updateActiveTab(.Right)
                },
                cancelCallback: { true },
                alwaysCallback: {
                    self.unlockUI()
                    self.showUI()
                }
            )
            leftViewController.presentViewController(loginOverlayViewController, animated: true, completion: nil)
            return
        }
        
        indicatedSide = side
        
        activeViewController.view.removeFromSuperview()
        activeViewController = isLeft ? leftViewController : rightViewController
        view.insertSubview(activeViewController.view, atIndex: 0)
    }
    
    private func updateIndicatedSide() {
        indicatedSideLayer.hidden = indicatedSide == nil
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let spacing = (view.frame.width / 2 - 35) / 2 - 31
        switch indicatedSide {
        case .Left?: indicatedSideLayer.frame = CGRect(x: spacing, y: 121, width: 62, height: 10)
        case .Right?: indicatedSideLayer.frame = CGRect(x: view.frame.width - spacing - 62, y: 121, width: 62, height: 10)
        default: ()
        }
        
        CATransaction.commit()
    }
    
    private func initNotificationIndicator() {
        let circle = UILabel()
        circle.frame = CGRect(x: rightButton.frame.origin.x + 25, y: rightButton.frame.origin.y - 3, width: 16, height: 16)
        circle.backgroundColor = .Accent
        circle.font = UIFont.displayOfSize(10, withType: .Regular)
        circle.textAlignment = .Center
        circle.textColor = .whiteColor()
        circle.layer.cornerRadius = 8
        circle.clipsToBounds = true
        circle.hidden = true
        uiWrapper.addSubview(circle)
        
        ActivitiesService.unreadCount.producer.startWithNext { count in
            let hidden = count <= 0
            circle.hidden = hidden
            circle.text = "\(count)"
        }
    }

}


class RecordButton: UIButton {
    
    private var touched = false
    
    private let progressLayer = CALayer()
    private let loadingView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    
    var icon: Icon = .Camera {
        didSet {
            setTitle(String.iconWithName(icon), forState: .Normal)
        }
    }
    
    var iconColor: UIColor = .whiteColor() {
        didSet {
            setTitleColor(iconColor.alpha(loading ? 0 : 1), forState: .Normal)
        }
    }
    
    var loading = false {
        didSet {
            if loading {
                loadingView.startAnimating()
            } else {
                loadingView.stopAnimating()
            }
            
            setTitleColor(titleColorForState(.Normal)!.alpha(loading ? 0 : 1), forState: .Normal)
            
            userInteractionEnabled = !loading
        }
    }
    
    var progressLocked = false {
        didSet {
            if !progressLocked {
                // reapply last progress value
                let tmp = progress
                progress = tmp
            }
        }
    }
    
    var progress: CGFloat? = nil {
        didSet {
            if !progressLocked {
                if let progress = progress {
                    backgroundColor = UIColor.Accent.mixWithColor(.blackColor(), amount: 0.3).alpha(0.5)
                    loading = progress != 1
                    
//                    if progress == 0 {
//                        icon = .Camera
//                    } else if progress == 1 {
//                        icon = .Next
//                    }
                } else {
                    backgroundColor = UIColor.Accent
                    loading = false
                }
                
                layoutSubviews()
            }
        }
    }
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        progressLayer.backgroundColor = UIColor.Accent.CGColor
        layer.addSublayer(progressLayer)
        
        loadingView.hidesWhenStopped = true
        addSubview(loadingView)
        
        backgroundColor = .Accent
        clipsToBounds = true
        
        layer.cornerRadius = 12
        
        setTitleColor(.whiteColor(), forState: .Normal)
        titleLabel?.font = UIFont.iconOfSize(33)
        
        addTarget(self, action: "buttonTouched", forControlEvents: .TouchDown)
        addTarget(self, action: "buttonUntouched", forControlEvents: [.TouchUpInside, .TouchUpOutside, .TouchCancel])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        progressLayer.frame = CGRect(x: 0, y: 0, width: frame.width * (progress ?? 0), height: frame.height)
        loadingView.fillSuperview()
    }
    
    private func updateBackground() {
        if touched {
            backgroundColor = UIColor.Accent.alpha(0.7)
        } else {
            backgroundColor = .Accent
        }
    }
    
    dynamic private func buttonTouched() {
        touched = true
        updateBackground()
    }
    
    dynamic private func buttonUntouched() {
        touched = false
        updateBackground()
    }
}

class TabButton: UIButton {
    
    enum Color { case Light, Dark }
    
    var title: String = "" {
        didSet {
            text.text = title
        }
    }
    
    var icon: Icon = .Cancel {
        didSet {
            setTitle(String.iconWithName(icon), forState: .Normal)
        }
    }
    
    var color: Color = .Dark {
        didSet {
            let actualColor = color == .Dark ? .whiteColor() : UIColor(0x919293)
            setTitleColor(actualColor, forState: .Normal)
            text.textColor = actualColor
            loadingView.color = actualColor
        }
    }
    
    var loading = false {
        didSet {
            if loading {
                loadingView.startAnimating()
            } else {
                loadingView.stopAnimating()
            }
            
            setTitleColor(titleColorForState(.Normal)!.alpha(loading ? 0 : 1), forState: .Normal)
            
            userInteractionEnabled = !loading
        }
    }
    
//    private let activeBorderLayer = CALayer()
    
    private let text = UILabel()
    private let loadingView = UIActivityIndicatorView()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        setTitleColor(.whiteColor(), forState: .Normal)
        titleLabel?.font = UIFont.iconOfSize(28)
        
        loadingView.hidesWhenStopped = true
        addSubview(loadingView)
        
        text.font = UIFont.displayOfSize(9, withType: .Light)
        text.textColor = .whiteColor()
        text.textAlignment = .Center
        addSubview(text)
        
//        activeBorderLayer.backgroundColor = UIColor.whiteColor().alpha(0.2).CGColor
//        layer.addSublayer(activeBorderLayer)
    }
    
    convenience init () {
        self.init(frame: CGRectZero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let textWidth: CGFloat = 50
        text.frame = CGRect(x: (frame.width - textWidth) / 2, y: frame.height + 10, width: textWidth, height: 11)
        
        loadingView.fillSuperview()
        
//        activeBorderLayer.frame = CGRect(x: -5, y: -5, width: frame.width + 10, height: frame.height + 10)
//        activeBorderLayer.cornerRadius = activeBorderLayer.frame.width / 2
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        let margin: CGFloat = 10
        let area = CGRectInset(bounds, -margin, -margin)
        return CGRectContainsPoint(area, point)
    }
    
}

protocol TabControllerDelegate {
    var tabController: TabViewController? { get }
    func jumpToTop()
    func scrollToOptograph(optographID: UUID)
    func onTouchStartCameraButton()
    func onTouchEndCameraButton()
    func onTapCameraButton()
    func onTapLeftButton()
    func onTapRightButton()
    func onTouchOneRingButton()
    func onTouchThreeRingButton()
}

extension TabControllerDelegate {
    func scrollToOptograph(optographID: UUID) {}
    func jumpToTop() {}
    func onTouchStartCameraButton() {}
    func onTouchEndCameraButton() {}
    func onTapCameraButton() {}
    func onTapLeftButton() {}
    func onTapRightButton() {}
    func onTouchOneRingButton() {}
    func onTouchThreeRingButton() {}
}

protocol DefaultTabControllerDelegate: TabControllerDelegate {}



extension DefaultTabControllerDelegate {
    
    func onTapCameraButton() {
        switch PipelineService.stitchingStatus.value {
        case .Idle:
            tabController!.leftViewController.cleanup()
            tabController!.rightViewController.cleanup()
            
            
            let alert:UIAlertController=UIAlertController(title: "Select Mode", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
            let cameraAction = UIAlertAction(title: "Optograph", style: UIAlertActionStyle.Default)
            {
                UIAlertAction in
                Defaults[.SessionUploadMode] = "opto"
                self.tabController!.activeViewController.pushViewController(CameraViewController(), animated: false)
            }
            let gallaryAction = UIAlertAction(title: "Upload Theta", style: UIAlertActionStyle.Default)
            {
                UIAlertAction in
                Defaults[.SessionUploadMode] = "theta"
                self.tabController!.openGallary()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel)
            {
                UIAlertAction in
            }
            alert.addAction(cameraAction)
            alert.addAction(gallaryAction)
            alert.addAction(cancelAction)
            
            tabController?.activeViewController.presentViewController(alert, animated: true, completion: nil)
            
        case .Stitching(_):
            let alert = UIAlertController(title: "Rendering in progress", message: "Please wait until your last image has finished rendering.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            tabController?.activeViewController.presentViewController(alert, animated: true, completion: nil)
        case let .StitchingFinished(optographID):
            scrollToOptograph(optographID)
            PipelineService.stitchingStatus.value = .Idle
        case .Uninitialized: ()
        }
    }
    
    func onTouchOneRingButton() {
        Defaults[.SessionUseMultiRing] = false
        tabController!.oneRingButton.backgroundColor = UIColor(red: 0.94, green: 0.28, blue: 0.21, alpha: 0.9)
        tabController!.threeRingButton.backgroundColor = UIColor.grayColor()
    }
    func onTouchThreeRingButton() {
        Defaults[.SessionUseMultiRing] = true
        tabController!.oneRingButton.backgroundColor = UIColor.grayColor()
        tabController!.threeRingButton.backgroundColor = UIColor(red: 0.94, green: 0.28, blue: 0.21, alpha: 0.9)
    }
    
    func onTapLeftButton() {
        if tabController?.activeViewController == tabController?.leftViewController {
            if tabController?.activeViewController.popToRootViewControllerAnimated(true) == nil {
                jumpToTop()
            }
        } else {
            tabController?.updateActiveTab(.Left)
        }
    }
    
    func onTapRightButton() {
        if tabController?.activeViewController == tabController?.rightViewController {
            if tabController?.activeViewController.popToRootViewControllerAnimated(true) == nil {
                jumpToTop()
            }
        } else {
            tabController?.updateActiveTab(.Right)
        }
    }
}

extension UIViewController {
    var tabController: TabViewController? {
        return navigationController?.parentViewController as? TabViewController
    }
    
    func updateTabs() {
        tabController!.leftButton.title = "HOME"
        tabController!.leftButton.icon = .Home
        tabController!.leftButton.hidden = false
        tabController!.leftButton.color = .Dark
        
        tabController!.rightButton.title = "PROFILE"
        tabController!.rightButton.icon = .User
        tabController!.rightButton.hidden = false
        tabController!.rightButton.color = .Dark
        
        tabController!.cameraButton.icon = .Camera
        tabController!.cameraButton.iconColor = .whiteColor()
        tabController!.cameraButton.backgroundColor = .Accent
        
        tabController!.bottomGradientOffset.value = 126
    }
    
    func cleanup() {}
}

extension UINavigationController {
    
    override func cleanup() {
        for vc in viewControllers ?? [] {
            vc.cleanup()
        }
    }
}

class PassThroughView: UIView {
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        for subview in subviews as [UIView] {
            if !subview.hidden && subview.alpha > 0 && subview.userInteractionEnabled && subview.pointInside(convertPoint(point, toView: subview), withEvent: event) {
                return true
            }
        }
        return false
    }
}