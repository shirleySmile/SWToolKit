//
//  UIViewController+NaviView.swift
//  SWToolKit
//
//  Created by shirley on 2022/4/14.
//

import Foundation
import UIKit


extension UIViewController {
    
    public var navBar:CNaviBar{
        get {
            let navBar:CNaviBar =  CNaviBar.getNaviView(currVC: self)
            navBar.showBottomLine = false
            return navBar
        }
    }
    
    
    /// 开关侧滑
    /// - Parameter open: 开关
    public func interactivePop(open:Bool){
        UIApplication.shared.isIdleTimerDisabled = !open
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = open;
    }
    
    /// 添加导航栏  默认显示
    /// - Parameter showBackView: 是否显示返回按钮
    public func showNaviView(showBack showBackView:Bool = true){
        navBar.showNaviView(show: showBackView)
        
//        self.navigationController?.navigationBar.isTranslucent = false

    }
    
    /// 隐藏导航栏
    public func hiddenNaviView(){
        navBar.hiddenNaviView()
    }
    
    /// 
    public func NaviViewAnimation(_ isShow:Bool){
        
    }
    
}
