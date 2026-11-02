//
//  UIView+ScreenPopup.swift
//  Pods
//
//  Created by muwa on 2025/11/26.
//


import UIKit
import SwiftUI

// MARK: - 弹窗显示参数

/// 弹窗显示参数（只放数据；delegate / 生命周期回调通过方法参数传入）
public struct ScreenPopupOptions {
    /// 显示动画
    public var animation: ScreenPopupAnimationType
    /// 遮罩色
    public var cover: UIColor?
    /// 是否允许点击弹窗外部关闭
    public var outside: Bool
    /// 点击弹窗外部的事件（nil 时默认关闭）
    public var outsideAction: ScreenPopupAction?
    /// 自定义 key，用于重复弹出 / 查询
    public var customKey: String?
    /// 点击穿透
    public var hitThrough: Bool

    public init(animation: ScreenPopupAnimationType = .none,
                cover: UIColor? = .black.withAlphaComponent(0.5),
                outside: Bool = true,
                outsideAction: ScreenPopupAction? = nil,
                customKey: String? = nil,
                hitThrough: Bool = false) {
        self.animation = animation
        self.cover = cover
        self.outside = outside
        self.outsideAction = outsideAction
        self.customKey = customKey
        self.hitThrough = hitThrough
    }
}

// MARK: - 尺寸变化数据

/// 弹窗尺寸变化时回传的数据
public struct ScreenPopupLayoutChange {
    /// 变化前的上级容器尺寸
    public let oldContainerSize: CGSize
    /// 变化后的上级容器尺寸；sheet 内容区的回调里为内容可用区域
    public let containerSize: CGSize
    /// 变化前自身的 frame；sheet 内容区的回调里为内容区 frame
    public let previousFrame: CGRect
    /// 库算出的默认 frame；didChange 时为最终生效的 frame；sheet 内容区的回调里为内容区 frame
    public let frame: CGRect
    /// 系统过渡动画时长，供调用方决定自己的动画；0 表示未知或无动画（如 iPad 分屏拖动）
    public let animationDuration: TimeInterval

    public init(oldContainerSize: CGSize,
                containerSize: CGSize,
                previousFrame: CGRect,
                frame: CGRect,
                animationDuration: TimeInterval) {
        self.oldContainerSize = oldContainerSize
        self.containerSize = containerSize
        self.previousFrame = previousFrame
        self.frame = frame
        self.animationDuration = animationDuration
    }
}


// MARK: - 弹窗代理

/// 弹窗生命周期 + 尺寸变化代理
public protocol ScreenPopupDelegate: AnyObject {
    /// 尺寸变化、落位前回调。返回 nil 使用库默认 frame；返回自定义 frame 则覆盖
    func screenPopupWillChange(_ change: ScreenPopupLayoutChange) -> CGRect?
    /// 尺寸变化、落位后回调（此时 frame 已生效）
    func screenPopupDidChange(_ change: ScreenPopupLayoutChange)
    /// 显示动画完成
    func screenPopupDidShow()
    /// 关闭回调（视图移除前）
    func screenPopupDidDismiss()
}

public extension ScreenPopupDelegate {
    func screenPopupWillChange(_ change: ScreenPopupLayoutChange) -> CGRect? { nil }
    func screenPopupDidChange(_ change: ScreenPopupLayoutChange) {}
    func screenPopupDidShow() {}
    func screenPopupDidDismiss() {}
}

///使用以下方法
extension UIView {
    
    /// 直接显示主屏幕上
    /// - Parameters:
    ///   - cover: 是否有遮盖色
    ///   - target: 目标
    ///   - action: 方法
    public func screenPopupShow(animation:ScreenPopupAnimationType = .none,
                                cover:UIColor? = .black.withAlphaComponent(0.5),
                                outside:Bool = true,
                                outsizeAction:ScreenPopupAction? = nil,
                                showCompletion:(()->Void)? = nil,
                                dismissCompletion:(()->Void)? = nil) {
        let view = ScreenPopupManager.shared.createBase(self, cover: cover, outside: outside, outsizeAction: outsizeAction)
        view.show(animation: animation, showCompletion: showCompletion, dismissCompletion: dismissCompletion)
    }

    /// 以参数结构 + 代理的方式显示弹窗
    /// - Parameters:
    ///   - options: 显示参数
    ///   - delegate: 尺寸变化 / 生命周期代理（weak 持有，调用方需自己持有）
    public func screenPopupShow(options: ScreenPopupOptions,
                                delegate: ScreenPopupDelegate? = nil) {
        let view = ScreenPopupManager.shared.createBase(self, cover: options.cover, outside: options.outside, outsizeAction: options.outsideAction)
        if let customKey = options.customKey {
            view.customKey = customKey
        }
        /// 显式 delegate 优先；未传时内容 view 自己实现协议就用自己
        view.popupDelegate = delegate ?? (self as? ScreenPopupDelegate)
        view.show(animation: options.animation,
                  through: options.hitThrough,
                  showCompletion: nil,
                  dismissCompletion: nil)
    }
    
    
    /// 删除屏幕的view
    public func screenPopupDismiss(_ animation:Bool = true) {
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
    public func screenPopupShow(key customKey:String,
                                viewFrame:CGRect,
                                show animation:ScreenPopupAnimationType = .none,
                                cover:UIColor? = .black.withAlphaComponent(0.5),
                                outside:Bool = true,
                                outsizeAction:ScreenPopupAction? = nil,
                                showCompletion:(()->Void)? = nil,
                                dismissCompletion:(()->Void)? = nil) {
        if let subView = UIHostingController(rootView: self).view {
            subView.frame = viewFrame
            subView.backgroundColor = .clear
            let view = ScreenPopupManager.shared.createBase(subView, cover: cover, outside: outside, outsizeAction: outsizeAction)
            view.customKey = customKey
            view.show(animation: animation, showCompletion: showCompletion, dismissCompletion: dismissCompletion)
        }
    }
    
    
    /// 删除屏幕的view
    public func screenPopupDismiss(key customKey:String, _ animation:Bool = true) {
        if let subView = ScreenPopupManager.getPopupView(key: customKey) {
            subView.screenPopupDismiss(animation)
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



