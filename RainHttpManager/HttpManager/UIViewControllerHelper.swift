//
//  UIViewControllerHelper.swift
//  RainHttpManager
//
//  Created by rainedAllNight on 2018/5/10.
//  Copyright © 2018年 luowei. All rights reserved.
//

import MBProgressHUD
import UIKit

extension UIViewController {
    
    public func setupHudStyle(_ hud: MBProgressHUD) {
        hud.bezelView.style = .blur
        hud.bezelView.color = .black
        hud.contentColor = .white
    }
    
    public func showProgressHUD(_ message: String) {
        self.dismissHUD()
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        self.setupHudStyle(hud)
        hud.label.text = message
    }
    
    public func showInfoHUD(_ info: String) {
        self.dismissHUD()
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        self.setupHudStyle(hud)
        hud.mode = .text
        hud.detailsLabel.text = info
        hud.detailsLabel.font = hud.label.font
        hud.hide(animated: true, afterDelay: 1.5)
    }
    
    public func showProgressHUD() {
        self.dismissHUD()
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        self.setupHudStyle(hud)
    }
    
    public func showStatusHUD(_ status: String) {
        self.dismissHUD()
        self.showProgressHUD(status)
    }
    
    public func showSuccessHUD(_ message: String) {
        if message.isEmpty {
            self.dismissHUD()
        } else {
            self.showInfoHUD(message)
        }
    }
    
    public func showErrorHUD(_ message: String) {
        if message.isEmpty {
            self.dismissHUD()
        } else {
            self.showInfoHUD(message)
        }
    }
    
    public func dismissHUD() {
        MBProgressHUD.hide(for: self.view, animated: true)
    }

}



