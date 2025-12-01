//
//  UIView+ScreenPopup.swift
//  Pods
//
//  Created by muwa on 2025/11/26.
//


import UIKit
import SwiftUI

///使用以下方法
extension UIView {
    
    /// 直接显示主屏幕上
    /// - Parameters:
    ///   - cover: 是否有遮盖色
    ///   - target: 目标
    ///   - action: 方法
    public func screenPopup(show animation:ScreenPopupAnimationType = .none,
                            cover:UIColor? = .black.withAlphaComponent(0.5),
                            outside:Bool = true,
                            outsizeAction:ScreenPopupAction? = nil) {
        let view = ScreenPopupManager.shared.createBase(self, cover: cover, outside: outside, outsizeAction: outsizeAction)
        view.show(animation: animation)
    }
    
    
    /// 删除屏幕的view
    public func screenPopupDsmiss(_ animation:Bool = true) {
        ScreenPopupManager.shared.closePopupView(popupView: self, animation: animation)
    }
    
    /// 将弹窗带到最顶层
    public func screenPopupBringToFront(){
        ScreenPopupManager.shared.bringViewToFront(popupView: self)
    }
    
}



extension View {
    
    /// 直接显示主屏幕上
    /// - Parameters:
    ///   - cover: 是否有遮盖色
    ///   - target: 目标
    ///   - action: 方法
    public func screenPopup(key customKey:String,
                            viewFrame:CGRect,
                            show animation:ScreenPopupAnimationType = .none,
                            cover:UIColor? = .black.withAlphaComponent(0.5),
                            outside:Bool = true,
                            outsizeAction:ScreenPopupAction? = nil) {
        if let subView = UIHostingController(rootView: self).view {
            subView.frame = viewFrame
            subView.backgroundColor = .clear
            let view = ScreenPopupManager.shared.createBase(subView, cover: cover, outside: outside, outsizeAction: outsizeAction)
            view.customKey = customKey
            view.show(animation: animation)
        }
    }
    
    
    /// 删除屏幕的view
    public func screenPopupDsmiss(key customKey:String, _ animation:Bool = true) {
        if let subView = ScreenPopupManager.getPopupView(key: customKey) {
            subView.screenPopupDsmiss(animation)
        }
    }
    
    /// 将弹窗带到最顶层
    public func screenPopupBringToFront(key customKey:String){
        if let subView = ScreenPopupManager.getPopupView(key: customKey) {
            subView.screenPopupBringToFront()
        }
    }
    
}



extension View {
    
    
    /// 显示弹窗view 带从底部弹出动画
    /// - Parameters:
    ///   - headerView: 标题view
    ///   - cover: 是否有遮盖色
    ///   - hidden: 点击view外侧是否自动隐藏
    ///   - cornerSize: 左右两角弧度
    ///   - dismiss: 开始隐藏的回调
    @discardableResult
    public func animationShow(key customKey:String,
                              viewFrame:CGRect,
                              cover:Bool = true,
                              header info:ScreenPopupSheetBorder.HeaderInfo? = nil,
                              autoHidden hidden:Bool = true,
                              backgroundColor:UIColor = .white,
                              cornerSize:CGSize = CGSize(width: 10, height: 10),
                              dismiss:DismissClosure? = nil) -> ScreenPopupSheetBorder? {
        
        let borderV = ScreenPopupManager.getPopupView(key: customKey)
        guard let bdV = borderV as? ScreenPopupSheetBorder else {
            if let subView = UIHostingController(rootView: self).view {
                subView.frame = viewFrame
                subView.backgroundColor = .clear
                /// 没值
                let borderView = ScreenPopupSheetBorder.init(frame: CGRect.zero)
                borderView.dimissBlock = dismiss
                borderView.createView(subView, headerInfo: info, cover: cover, hidden: hidden, cornerSize: cornerSize, btmHeight: 0, bgColor: backgroundColor)
                borderView.popView?.customKey = customKey
                borderView.showView(animation: true)
                return borderView
            }
            return nil
        }
        ///到这就是有值了
        return bdV
    }
    
    /// 隐藏弹窗
    public func animationDismiss(key customKey:String, _ animation:Bool = true){
        let borderV = ScreenPopupManager.getPopupView(key: customKey)
        guard let borderView = borderV as? ScreenPopupSheetBorder else {
            return
        }
        borderView.dismissSheetBorderView(animation: animation)
    }
    
    
    public func checkAnimationPopupView(key customKey:String) -> Bool {
        let borderV = ScreenPopupManager.getPopupView(key: customKey)
        guard let _ = borderV as? ScreenPopupSheetBorder else {
            return false
        }
        return true
    }
    
    
}



