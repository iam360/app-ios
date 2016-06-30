//
//  InvitationViewController.swift
//  DSCVR
//
//  Created by robert john alkuino on 6/30/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit

class InvitationViewController: UIViewController,UITextFieldDelegate {

    
    var label1 = UILabel()
    var label2 = UILabel()
    var label3 = UILabel()
    var logoImageView = UIImageView()
    var textPutCode = UITextField()
    var textRequestCode = UITextField()
    var buttonPutCode = UIButton()
    var view1 = UIView()
    var orImage = UIImageView()
    var requestButton = UIButton()
    var backView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        backView.backgroundColor = UIColor(hex:0x343434)
        view.addSubview(backView)
        backView.fillSuperview()
        
        let logo: UIImage = UIImage(named: "logo_invite")!
        logoImageView.image = logo
        backView.addSubview(logoImageView)
        
        let dragTextWidth = calcTextWidth("Type Super Secret Code", withFont: .displayOfSize(20, withType: .Semibold))
        label1.text = "Type Super Secret Code"
        label1.font = UIFont(name: "Avenir-Book", size: 20)
        label1.backgroundColor = UIColor.clearColor()
        label1.textColor = UIColor.whiteColor()
        label1.textAlignment = .Center
        backView.addSubview(label1)
        
        view1.backgroundColor = UIColor.clearColor()
        backView.addSubview(view1)
        
        textPutCode.backgroundColor = UIColor(hex:0xCACACA)
        textPutCode.layer.cornerRadius = 4
        view1.addSubview(textPutCode)
        
        buttonPutCode.setTitle("GO", forState: .Normal)
        buttonPutCode.layer.cornerRadius = 4
        buttonPutCode.titleLabel!.font =  UIFont(name: "Helvetica", size: 12)
        buttonPutCode.backgroundColor = UIColor(hex:0xffbc00)
        buttonPutCode.setTitleColor(UIColor(hex:0x343434), forState: .Normal)
        buttonPutCode.addTarget(self,action: #selector(pushCode),forControlEvents: .TouchUpInside)
        view1.addSubview(buttonPutCode)
        
        let orText: UIImage = UIImage(named: "or_icn")!
        orImage.image = orText
        backView.addSubview(orImage)
        
        label2.text = "Request Super Secret Code"
        label2.font = UIFont(name: "Avenir-Book", size: 20)
        label2.backgroundColor = UIColor.clearColor()
        label2.textAlignment = .Center
        label2.textColor = UIColor.whiteColor()
        backView.addSubview(label2)
        
        textRequestCode.backgroundColor = UIColor(hex:0xCACACA)
        textRequestCode.layer.cornerRadius = 4
        textRequestCode.placeholder = "   E-mail"
        textRequestCode.textColor = UIColor.whiteColor()
        backView.addSubview(textRequestCode)
        
        requestButton.setTitle("REQUEST", forState: .Normal)
        requestButton.layer.cornerRadius = 4
        requestButton.titleLabel!.font =  UIFont(name: "Helvetica", size: 12)
        requestButton.backgroundColor = UIColor(hex:0xffbc00)
        requestButton.setTitleColor(UIColor(hex:0x343434), forState: .Normal)
        requestButton.addTarget(self,action: #selector(pushCode),forControlEvents: .TouchUpInside)
        backView.addSubview(requestButton)
        
        label3.text = "Reach us at TEAM@DSCVR.COM"
        label3.font = UIFont(name: "Avenir-Book", size: 17)
        label3.backgroundColor = UIColor.clearColor()
        label3.textAlignment = .Center
        label3.textColor = UIColor.whiteColor()
        backView.addSubview(label3)
        
        logoImageView.anchorToEdge(.Top, padding: 60, width: logo.size.width, height: logo.size.height)
        label1.align(.UnderCentered, relativeTo: logoImageView, padding: 55, width: dragTextWidth, height: 25)
        
        let viewwidth = (view.frame.width-49)/3
        
        textPutCode.anchorInCorner(.TopLeft, xPad: 0, yPad: 0, width: (viewwidth * 2)+20, height: 50)
        buttonPutCode.align(.ToTheRightMatchingBottom, relativeTo: textPutCode, padding: 5, width: viewwidth - 20, height: 50)
        view1.align(.UnderCentered, relativeTo: label1, padding: 16, width: view.frame.width-49, height: 50)
        orImage.align(.UnderCentered, relativeTo: view1, padding: 49, width: orText.size.width, height: orText.size.height)
        label2.align(.UnderCentered, relativeTo: orImage, padding: 22, width: view.frame.width-44, height: 50)
        
        textRequestCode.align(.UnderCentered, relativeTo: label2, padding: 16, width: view.frame.width-44, height: 50)
        requestButton.align(.UnderCentered, relativeTo: textRequestCode, padding: 13, width: view.frame.width-44, height: 50)
        
        let footerWidth = calcTextWidth("Reach us at TEAM@DSCVR.COM", withFont: .displayOfSize(17, withType: .Semibold))
        label3.anchorToEdge(.Bottom, padding: 10, width: footerWidth, height:20)
        
        textPutCode.delegate = self
        textRequestCode.delegate = self
        backView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeKeyboard)))
        
    }
    func pushCode() {
    
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let keyboardHeight = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
        if textRequestCode.isFirstResponder() {
            backView.frame = CGRect(x: 0,y: backView.frame.origin.y - keyboardHeight ,width: view.frame.width,height: view.frame.height)
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let keyboardHeight = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
        if textRequestCode.isFirstResponder() {
            backView.frame = CGRect(x: 0,y: backView.frame.origin.y + keyboardHeight ,width: view.frame.width,height: view.frame.height)
        }
        
    }
    func closeKeyboard() {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
