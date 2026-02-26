//
//  ScreenPopupManager.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/3.
//

import Foundation
import UIKit
import SwiftUI



/// 显示的动画
public enum ScreenPopupAnimationType {
    /// 从屏幕顶部向下
    case enterFromTop(spring:Bool = false)
    /// 从屏幕底部向上
    case enterFromBottom(spring:Bool = false)
    /// 居中- 从小发大
    case enterFromCenter(enlarged:Bool = false)
    /// 无
    case none
}

/// 外部添加事件
public struct ScreenPopupAction {
    var target:Any
    var action:Selector
}



public class ScreenPopupManager : NSObject {
    ///单例
    public static let shared = ScreenPopupManager()
     
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
    public weak var externalPopupBgView:UIView? {
        willSet{
            ScreenPopupManager.removeAllPopupView()
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
                _windowUpPopupBgView = ScreenPopupBackgroundView.init(frame:(winView?.bounds ?? CGRect(x: 0, y: 0, width: kScreen.width, height: kScreen.height)))
                winView?.addSubview(_windowUpPopupBgView!)
                NotificationCenter.default.post(name: .windowBringSubview, object: nil)
                return _windowUpPopupBgView!
            }
             
            if let superV = bgV.superview, superV.isKind(of: UIWindow.self), let lastView = superV.subviews.last, lastView.tag != ScreenPopupBackgroundView.viewTag {
                ///UITransitionView 这个view不知道从哪里出现的， 会遮盖window上的view
                if NSStringFromClass(lastView.classForCoder).self == "UITransitionView" {
                    superV.sendSubviewToBack(lastView)
//                    ///删除了哈
//                    lastView.removeFromSuperview()
                }
                /// 将弹窗view提到最前面
                if bgV.tag == ScreenPopupBackgroundView.viewTag {
                    NotificationCenter.default.post(name: .windowBringSubview, object: nil)
                    superV.bringSubviewToFront(bgV)
                }
            }
            ///有值
            return bgV
        }
    }
}




///弹窗处理
extension ScreenPopupManager {
        
    /// 显示弹窗
    public func show(_ popupView:UIView,
                     show animation:ScreenPopupAnimationType = .none,
                     cover bgColor:UIColor?,
                     outside:Bool,
                     outsizeAction:ScreenPopupAction? = nil,
                     showCompletion:(()->Void)? = nil,
                     dismissCompletion:(()->Void)? = nil) {
        let view = ScreenPopupManager.shared.createBase(popupView, cover: bgColor, outside: outside, outsizeAction: outsizeAction)
        view.show(animation: animation, showCompletion: showCompletion, dismissCompletion: dismissCompletion)
    }
    
    
    /// 关闭弹窗
    /// - Parameters:
    ///   - popupView: 弹窗的view
    ///   - animation: 是否播放动画
    public func dismiss(popupView:UIView, animation:Bool = true){
        self.closePopupView(popupView: popupView, animation: animation)
    }
        
    ///清空所有
    public static func removeAllPopupView(){
        ScreenPopupManager.shared.closeAllPopups()
    }
    
    
    //获得popupClass的实体
    public static func getPopupView(popupV:AnyObject) -> UIView?{
        let popBgView = ScreenPopupManager.shared._windowUpPopupBgView ?? ScreenPopupManager.shared.externalPopupBgView
        if let bgView =  popBgView {
            for popBaseV in bgView.subviews {
                if let popV = popBaseV as? ScreenPopupOnePiece, let lineView = popV.outlinkView {
                    if lineView.isMember(of: popupV.classForCoder) {
                        return popV.outlinkView
                    }
                }
            }
        }
        return nil
    }
    
    // 根据自定义key查询弹窗view
    public static func getPopupView(key customKey:String) -> UIView? {
        let popBgView = ScreenPopupManager.shared._windowUpPopupBgView ?? ScreenPopupManager.shared.externalPopupBgView
        if let bgView =  popBgView {
            for popBaseV in bgView.subviews {
                if let popV = popBaseV as? ScreenPopupOnePiece {
                    if  popV.customKey == customKey {
                        return popV.outlinkView
                    }
                }
            }
        }
        return nil
    }
    
}



/// 提供给SheetBorder使用
extension ScreenPopupManager {
    
    /// -----双层主视图使用-----显示弹窗 (子视图是主视图)
    /// - Parameters:
    ///   - popupView: 弹窗的view
    ///   - mainView: 双层UI的主视图
    ///   - action: 点击弹窗外区域对应的方法
    ///   - target: 点击弹窗外区域对应的方法的对象
    ///   - cover: 是否有默认背景颜色。默认no-无色
    func createMutiPopupView(popupView:UIView, mainView:UIView, action:Selector?, target:Any?, cover:Bool, bgAlpha:CGFloat = 0.3) -> ScreenPopupOnePiece {
        let baseView = ScreenPopupOnePiece.init(frame: screenBgView.bounds, outlink: popupView)
        baseView.delegate = self
        self.screenBgView.addSubview(baseView)
        baseView.subMainView = mainView;
        baseView.bgColor = .black.withAlphaComponent(cover ? bgAlpha : 0)
        if let target, let action {
            baseView.outside(.init(target: target, action: action))
        }
        return baseView
    }
    
    
    ///-----双层主视图使用-----根据弹窗主视图获取弹窗视图
    static func getMutiPopupView(popupV:UIView) -> UIView? {
        let popBgView = ScreenPopupManager.shared._windowUpPopupBgView ?? ScreenPopupManager.shared.externalPopupBgView
        if let superV = popBgView{
            for popBaseV in superV.subviews {
                if popBaseV.isKind(of: ScreenPopupOnePiece.self){
                    if let popV = popBaseV as? ScreenPopupOnePiece, let subMainV = popV.subMainView {
                        if subMainV.isMember(of: popupV.classForCoder){
                            return popV.outlinkView
                        }
                    }
                }
            }
        }
        return nil
    }

}


/// ScreenPopupOnePieceDelegate
extension ScreenPopupManager: ScreenPopupOnePieceDelegate {
    
    /// 删除弹窗控制页面中的视图
    func screenPopop(close view: ScreenPopupOnePiece) {
        self.dismissPopManagerView(view)
    }

}


/// private
extension ScreenPopupManager {
    
    
    /// 显示弹窗
    /// - Parameters:
    ///   - popupView: 需要弹出的view
    ///   - bgColor: 背景色
    ///   - outside: 是否允许点击弹窗外部关闭弹窗
    ///   - outsizeAction: 点击弹窗以外区域的外部事件
    /// - Returns: 返回一个弹窗管理视图
    func createBase(_ popupView:UIView,
                                cover bgColor:UIColor?,
                                outside:Bool,
                                outsizeAction:ScreenPopupAction? = nil) -> ScreenPopupOnePiece {
        
        let baseView = ScreenPopupOnePiece.init(frame: self.screenBgView.bounds, outlink: popupView)
        baseView.delegate = self
        self.screenBgView.addSubview(baseView)
        baseView.bgColor = bgColor
        if outside {
            baseView.outside(outsizeAction)
        }
        return baseView
    }
    
    ///获得当前的baseView
    private func getPopDownView(popupView:UIView?) -> ScreenPopupOnePiece? {
        var searchView:ScreenPopupOnePiece?
        for subV in screenBgView.subviews {
            if let oneBaseV = (subV as? ScreenPopupOnePiece) {
                if oneBaseV.outlinkView == popupView {
                    searchView = oneBaseV
                    break
                }
            }
        }
        return searchView
    }
    
    /// 关闭某个弹窗
    func closePopupView(popupView:UIView?, animation:Bool) {
        let searchView = getPopDownView(popupView: popupView)
        searchView?.dismiss(animation: animation)
    }


    /// 将弹窗带到最顶层
    func bringViewToFront(popupView:UIView){
        for popBaseV in ScreenPopupManager.shared.screenBgView.subviews {
            if let popV = popBaseV as? ScreenPopupOnePiece {
                if popV.outlinkView == popupView {
                    popV.superview?.bringSubviewToFront(popV)
                }
            }
        }
    }
    
    /// 删除一个弹窗管理视图
    fileprivate func dismissPopManagerView(_ popView:ScreenPopupOnePiece?){
        popView?.removeFromSuperview()
        /// 判断当前视图是否有内容，若无内容则删除主视图
        if _windowUpPopupBgView?.subviews.count == 0 {
            _windowUpPopupBgView?.removeFromSuperview()
            _windowUpPopupBgView = nil
        }
    }
    
    /// 关闭所有弹窗
    fileprivate func closeAllPopups() {
        for subItemV in screenBgView.subviews {
            if subItemV is ScreenPopupOnePiece {
                subItemV.removeFromSuperview()
            }
        }
        _windowUpPopupBgView?.removeFromSuperview()
        _windowUpPopupBgView = nil
    }

    
}


