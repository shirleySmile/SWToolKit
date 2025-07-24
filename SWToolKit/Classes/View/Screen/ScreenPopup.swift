//
//  ScreenPopup.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/3.
//

import Foundation
import UIKit
import SwiftUI


class OnePopupBaseView : UIView {
    
    var lineView:UIView?
    ///主图
    var subMainView:UIView?
    /// 背景色的透明度
    var bgAlpha:CGFloat?
    ///是否有背景色
    var hasBgColor:Bool = false{
        didSet{
            self.backgroundColor = hasBgColor ? UIColor(0x000000).withAlphaComponent(bgAlpha ?? 0.5) : UIColor.clear
        }
    }
    
}


public class ScreenPopup : NSObject, UIGestureRecognizerDelegate {
    ///单例
    public static let share = ScreenPopup()
     
    private override init() { }
    
    public override class func copy() -> Any {
        return self
    }
    public override class func mutableCopy() -> Any {
        return self
    }
    
    ///当前在基层弹出窗口(window上的view)
    private var _windowUpPopupBgView:UIView?
    ///外部设置的底层控制view（不传就默认）
    public var externalPopupBgView:UIView?{
        willSet{
            ScreenPopup.removeAllPopupView()
        }
    }
    
    ///弹窗基层View
    private var screenBgView: UIView{
        get{
            /// 先用内部设置的view
            if let exterView = externalPopupBgView {
                return exterView
            }
            /// 没有外部设置的view就用内部的view
            guard let bgV = _windowUpPopupBgView else {
                let winView = kHighWindow
                _windowUpPopupBgView = HitThroughView.init(frame:(winView?.bounds ?? CGRect(x: 0, y: 0, width: kScreen.width, height: kScreen.height)))
                _windowUpPopupBgView?.tag = 123456789
                winView?.addSubview(_windowUpPopupBgView!)
                NotificationCenter.default.post(name: .windowBringSubview, object: nil)
                return _windowUpPopupBgView!
            }
             
            if let superV = bgV.superview, superV.isKind(of: UIWindow.self), let lastView = superV.subviews.last, lastView.tag != 123456789 {
                ///UITransitionView 这个view不知道从哪里出现的， 会遮盖window上的view
                if NSStringFromClass(lastView.classForCoder).self == "UITransitionView" {
                    superV.sendSubviewToBack(lastView)
//                    ///删除了哈
//                    lastView.removeFromSuperview()
                }
                /// 将弹窗view提到最前面
                if bgV.tag == 123456789 {
                    NotificationCenter.default.post(name: .windowBringSubview, object: nil)
                    superV.bringSubviewToFront(bgV)
                }
            }
            ///有值
            return bgV
        }
    }
    
    
    /**
     显示弹窗
     @param popupView   需要弹出的view
     @param alpha   底色透明度
     @param tapOutside 点击弹窗外区域是否隐藏view
     @param action          点击弹窗外区域对应的方法
     @param target          点击弹窗外区域对应的方法的对象
     */
    fileprivate func createBase(_ popupView:UIView, outside:Bool, action:Selector?, target:Any?, cover:Bool, bgAlpha:CGFloat?, center:Bool) -> () {
        
        let baseView = OnePopupBaseView.init(frame: self.screenBgView.bounds)
        baseView.isUserInteractionEnabled = true
        self.screenBgView.addSubview(baseView)
        baseView.lineView = popupView
        baseView.bgAlpha = bgAlpha
        baseView.hasBgColor = cover
        if center {
            popupView.center = CGPoint.init(x: baseView.width/2.0, y: baseView.height/2.0)
        }
        baseView.addSubview(popupView)
        
        if outside {
            if target != nil && action != nil {
                let tap = UITapGestureRecognizer.init(target: target, action: action)
                tap.delegate = self
                baseView.addGestureRecognizer(tap)
            }else{
                if center == true{
                    let tap = UITapGestureRecognizer.init(target: self, action: #selector(clickHiddenTapCenter(tapGR:)))
                    tap.delegate = self
                    baseView.addGestureRecognizer(tap)
                }else{
                    let tap = UITapGestureRecognizer.init(target: self, action: #selector(clickHiddenTapDown(tapGR:)))
                    tap.delegate = self
                    baseView.addGestureRecognizer(tap)
                }
                 
            }
        }
    }
    
    ///获得当前的baseView
    private func getPopDownView(popupView:UIView?) -> OnePopupBaseView? {
        var searchView:OnePopupBaseView?
        for subV in screenBgView.subviews {
            if let oneBaseV = (subV as? OnePopupBaseView) {
                if oneBaseV.lineView == popupView {
                    searchView = oneBaseV
                    break
                }
            }
        }
        return searchView
    }
    
    //// 关闭某个弹窗
    fileprivate func closePopupView(popupView:UIView?) {
        let search = getPopDownView(popupView: popupView)
        search?.lineView?.removeFromSuperview()
        search?.subMainView?.removeFromSuperview()
        search?.removeFromSuperview()
        if _windowUpPopupBgView?.subviews.count == 0 {
            _windowUpPopupBgView?.removeFromSuperview()
            _windowUpPopupBgView = nil
        }
    }
    
    
    private func showPopupView(popupView: UIView) {
        var tempF = popupView.frame
        tempF.origin.y = kScreen.height-tempF.height-(kDevice.isPad && popupView.width < kScreen.width ? 10 : 0)
        popupView.frame = tempF
    }
    
    ///点击事件
    @objc private func clickHiddenTapCenter(tapGR:UITapGestureRecognizer){
        let tapV = tapGR.view
        guard let tapView = (tapV as? OnePopupBaseView) else {
            return
        }
        
        if let lineView = tapView.lineView {
            closePopupView(popupView: lineView)
        }
    }
    
    ///点击事件
    @objc private func clickHiddenTapDown(tapGR:UITapGestureRecognizer){
        let tapV = tapGR.view
        guard let tapView = (tapV as? OnePopupBaseView) else {
            return
        }
        
        if let lineView = tapView.lineView {
            self.dismiss(popupView: lineView)
        }
    }
    
    /// 将弹窗带到最顶层
    fileprivate func bringViewToFront(popupView:UIView){
        for popBaseV in ScreenPopup.share.screenBgView.subviews {
            if let popV = popBaseV as? OnePopupBaseView {
                if popV.lineView == popupView {
                    popV.superview?.bringSubviewToFront(popV)
                }
            }
        }
    }
    
    ///点击代理
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let _ = touch.view as? OnePopupBaseView else{
            return false
        }
        return true
    }
}



///使用以下方法
extension UIView {
    
    /// 直接显示主屏幕上
    /// - Parameters:
    ///   - cover: 是否有遮盖色
    ///   - target: 目标 
    ///   - action: 方法
    public func screenPopupShow(cover:Bool = false, bgColorA:CGFloat? = nil, outside:Bool = true, target:Any? = nil, action:Selector? = nil, center:Bool = true) {
        ScreenPopup.share.createBase(self, outside: outside, action: action, target: target, cover: cover, bgAlpha: bgColorA, center: center)
    }
    

    /// 删除屏幕的view
    public func screenPopupDismiss() {
        ScreenPopup.share.closePopupView(popupView: self)
    }
    
    /// 将弹窗带到最顶层
    public func screenPopupBringToFront(){
        ScreenPopup.share.bringViewToFront(popupView: self)
    }
    
}

///弹窗处理
extension ScreenPopup {
    
    /// view显示动画 ---从下往上进入
    /// - Parameters:
    ///   - popupView: 弹窗的view
    ///   - animation: 是否有动画
    public func show(popupView:UIView, animation:Bool = true){
        popupView.origin.x = (kDevice.isPad && (kScreen.width != popupView.width)) ? (kScreen.width - popupView.width - 10) : 0
        if animation {
            weak var weakself = self
            UIView.animate(withDuration: 0.25) {
                weakself?.showPopupView(popupView: popupView)
            } 
        }else{
            showPopupView(popupView: popupView)
        }
    }
    
    
    /// 关闭弹窗 ---从上往下退出
    /// - Parameters:
    ///   - popupView: 弹窗的view
    ///   - animation: 是否有动画
    public func dismiss(popupView:UIView, animation:Bool = true){
        if animation {
            UIView.animate(withDuration: 0.25) {
                var tempF = popupView.frame
                tempF.origin.y = kScreen.height
                popupView.frame = tempF
            } completion: { finish in
                self.closePopupView(popupView: popupView)
            }
        }else{
            closePopupView(popupView: popupView)
        }
    }
        
    ///清空所有
    public static func removeAllPopupView(){
        for subItemV in ScreenPopup.share.screenBgView.subviews {
            if subItemV is OnePopupBaseView {
                subItemV.removeFromSuperview()
            }
        }
        ScreenPopup.share._windowUpPopupBgView?.removeFromSuperview()
        ScreenPopup.share._windowUpPopupBgView = nil
    }
    
    
    //获得popupClass的实体
    public static func getPopupView(popupV:AnyObject) -> UIView?{
        let popBgView = ScreenPopup.share._windowUpPopupBgView ?? ScreenPopup.share.externalPopupBgView
        if let bgView =  popBgView {
            for popBaseV in bgView.subviews {
                if let popV = popBaseV as? OnePopupBaseView, let lineView = popV.lineView {
                    if lineView.isMember(of: popupV.classForCoder) {
                        return popV.lineView
                    }
                }
            }
        }
        return nil
    }
    
}



/// 提供给SheetBorder使用
extension ScreenPopup {
    
    /// -----双层主视图使用-----显示弹窗 (子视图是主视图)
    /// - Parameters:
    ///   - popupView: 弹窗的view
    ///   - mainView: 双层UI的主视图
    ///   - action: 点击弹窗外区域对应的方法
    ///   - target: 点击弹窗外区域对应的方法的对象
    ///   - cover: 是否有默认背景颜色。默认no-无色
    func createMutiPopupView(popupView:UIView, mainView:UIView, action:Selector?, target:Any?, cover:Bool, bgAlpha:CGFloat = 1.0){
        let baseView = OnePopupBaseView.init(frame: screenBgView.bounds)
        baseView.isUserInteractionEnabled = true
        self.screenBgView.addSubview(baseView)
        baseView.lineView = popupView
        baseView.subMainView = mainView;
        baseView.hasBgColor = cover
        baseView.bgAlpha = bgAlpha
        baseView.addSubview(popupView)
        if  target != nil && action != nil {
            let tap = UITapGestureRecognizer.init(target: target, action: action)
            tap.delegate = self
            baseView.addGestureRecognizer(tap)
        }
    }
    
    
    ///-----双层主视图使用-----根据弹窗主视图获取弹窗视图
    static func getMutiPopupView(popupV:UIView) -> UIView? {
        let popBgView = ScreenPopup.share._windowUpPopupBgView ?? ScreenPopup.share.externalPopupBgView
        if let superV = popBgView{
            for popBaseV in superV.subviews {
                if popBaseV.isKind(of: OnePopupBaseView.self){
                    if let popV = popBaseV as? OnePopupBaseView, let subMainV = popV.subMainView {
                        if subMainV.isMember(of: popupV.classForCoder){
                            return popV.lineView
                        }
                    }
                   
                }
            }
        }
        return nil
    }

}
