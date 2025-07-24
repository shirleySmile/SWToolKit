//
//  SheetBorder.swift
//  SWToolKit
//
//  Created by shirley on 2022/5/25.
//

import Foundation
import UIKit


public typealias DismissClosure = () -> Void

///弹出view的包边
open class SheetBorder: UIView {

    ///dimiss回调
    public var dimissBlock:DismissClosure?
    fileprivate var animationShow:Bool = true
    
    ///创建view
    public func createView(_ detailV:UIView, headerV:UIView?, cover:Bool, hidden:Bool, cornerSize:CGSize, btmHeight:CGFloat,
                                bgColor:UIColor) {
        
        let detailH:CGFloat = detailV.height
        let headerH:CGFloat = (headerV?.height ?? 0)
        
        self.frame = CGRect.init(x: 0, y: kScreen.height, width: detailV.width, height: detailH + headerH + btmHeight)
        self.backgroundColor = bgColor
        
        headerV?.frame = CGRect(x: 0, y: 0, width: detailV.width, height: headerH);
        detailV.y = headerV?.maxY ?? 0
        if let headerView = headerV {
            self.addSubview(headerView)
        }
        self.addSubview(detailV)

        if !cornerSize.equalTo(.zero){
            self.cornerRadii(size: cornerSize, corners: [.topLeft,.topRight])
            
            if kDevice.isPad && detailV.width < kScreen.width {
                self.cornerRadii(size: cornerSize, corners: .allCorners)
            }
        }

        ScreenPopup.share.createMutiPopupView(popupView: self, mainView: detailV, action: (hidden ? #selector(dismissView) : nil), target: (hidden ? self : nil), cover: cover)
    }
    
    @objc fileprivate func dismissView(){
        dismissSheetBorderView(animation: animationShow)
    }
    
    public func dismissSheetBorderView(animation:Bool){
        self.endEditing(true)
        self.dimissBlock?()
        ScreenPopup.share.dismiss(popupView: self, animation: animation)
    }
    
    public func showView(animation:Bool = true){
        ScreenPopup.share.show(popupView: self, animation: animation)
    }
}


///只支持view添加动画效果
extension UIView {
    
    
    /// 显示弹窗view 带从底部弹出动画
    /// - Parameters:
    ///   - headerView: 标题view
    ///   - cover: 是否有遮盖色
    ///   - hidden: 点击view外侧是否自动隐藏
    ///   - cornerSize: 左右两角弧度
    ///   - dismiss: 开始隐藏的回调
    @discardableResult
    public func animationShow(cover:Bool = true,
                              headerView :UIView? = nil,
                              animation:Bool = true,
                              autoHidden hidden:Bool = true,
                              bottomHeight:CGFloat = max(kSafeBtmH, 20),
                              backgroundColor:UIColor = .white,
                              cornerSize:CGSize = CGSize(width: 10, height: 10),
                              dismiss:DismissClosure? = nil) -> SheetBorder?{
        
        let borderV = ScreenPopup.getMutiPopupView(popupV: self)
        guard let bdV = borderV as? SheetBorder else {
            /// 没值
            let borderView = SheetBorder.init(frame: CGRect.zero)
            borderView.dimissBlock = dismiss
            borderView.animationShow = animation
            borderView.createView(self, headerV: headerView, cover: cover, hidden: hidden, cornerSize: cornerSize, btmHeight: bottomHeight, bgColor:backgroundColor)
            borderView.showView(animation: animation)
            return borderView
        }
        ///到这就是有值了
        return bdV
    }
    
    /// 隐藏弹窗
    public func animationDismiss(animation:Bool = true){
        let borderV = ScreenPopup.getMutiPopupView(popupV: self)
        guard let borderView = borderV as? SheetBorder else {
            return
        }
        borderView.dismissSheetBorderView(animation: animation)
    }
    
    
    public func checkAnimationPopupView() -> Bool {
        let borderV = ScreenPopup.getMutiPopupView(popupV: self)
        guard let _ = borderV as? SheetBorder else {
            return false
        }
        return true
    }
    
    
}
