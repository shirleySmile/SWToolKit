//
//  ScreenPopupSheetBorder.swift
//  SWToolKit
//
//  Created by shirley on 2022/5/25.
//

import Foundation
import UIKit

public typealias DismissClosure = () -> Void



/// 带下滑手势的View
open class SheetBorderSliderHeader: UIView {
    
    fileprivate var dismissClosure:(()->Void)?
    fileprivate var panLinkView:UIView? {
        didSet {
            panLinkView?.layoutIfNeeded()
        }
    }

    /// 当前容器高度（旋转 / 分屏后实时计算，不再缓存）
    private var containerHeight: CGFloat {
        if let superV = panLinkView?.superview, superV.bounds.height > 0 {
            return superV.bounds.height
        }
        return kScreen.height
    }

    /// 贴底时的 y
    private var settledY: CGFloat {
        containerHeight - (panLinkView?.height ?? 0)
    }
    
    lazy var sliderView:UIView = {
        let bgView = UIView()
        bgView.layerCorner(radius: 3)
        bgView.isUserInteractionEnabled = false
        bgView.backgroundColor = .color(hex: "#D9D9D9")
        return bgView
    }()
    
    
    public init(viewHeight:CGFloat = 30) {
        super.init(frame: .init(x: 0, y: 0, width: 0, height: max(viewHeight, 20)))
        self.create()
    }
    
    override init(frame: CGRect) {
        super.init(frame: .init(origin: .zero, size: .init(width: 0, height: max(30, frame.height))))
        self.create()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        sliderView.center = .init(x: self.width/2.0, y: 9 + sliderView.height/2.0)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func create() {
        sliderView.frame = .init(x: 100, y: 6, width: 44.0, height: 6.0)
        self.addSubview(sliderView)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        self.addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == .began {
            self.panLinkView?.endEditing(true)
        }
        guard let linkView = self.panLinkView else { return }
        let translation = gestureRecognizer.translation(in: linkView)
        
        // 将视图的位置根据手势的移动进行调整
        // 只允许向下移动
        let centerY:CGFloat = linkView.center.y + translation.y
        let pointY:CGFloat = centerY - linkView.height/2.0
        if pointY >= settledY {
//        if translation.y > 0 {
            // 将视图的位置根据手势的移动进行调整
            if let _ = gestureRecognizer.view {
                linkView.center = CGPoint(x: linkView.center.x, y: centerY)
            }
        }
        
        // 当手势结束时，实现反弹效果
        if gestureRecognizer.state == .ended {
            if let _ = gestureRecognizer.view {
                if linkView.origin.y - settledY > (linkView.height * 1.0 / 3.0){
                    self.dismiss()
                }else{
                    let originY = self.settledY
                    if originY <= 0 {
                        self.dismiss()
                    } else {
                        UIView.animate(withDuration: 0.25) {
                            // 将视图的位置恢复到原始位置
                            linkView.y = originY
                        } completion: { finish in
                        }
                    }
                }
            }
        }
        gestureRecognizer.setTranslation(CGPoint.zero, in: linkView)
    }
    
    /// 关闭
    @objc func dismiss() {
        self.dismissClosure?()
    }
    
    /// 默认头部
    public static func headerInfo() -> ScreenPopupSheetBorder.HeaderInfo {
        let headerV = SheetBorderSliderHeader(viewHeight: 30)
        return ScreenPopupSheetBorder.HeaderInfo.init(view: headerV)
    }
}



///弹出view的包边
open class ScreenPopupSheetBorder: UIView, ScreenPopupDelegate {

    public enum HeaderType {
        /// 内容视图的顶部
        case vertical
        /// 遮盖在内容视图的顶部
        case cover
    }
    
    public struct HeaderInfo {
        var view:UIView
        var type:HeaderType = .vertical
        
        public init(view: UIView, type: HeaderType = .vertical) {
            self.view = view
            self.type = type
        }
    }
    
    ///dimiss回调
    public var dimissBlock:DismissClosure?
    private(set) weak var popView:ScreenPopupOnePiece?
    /// 内容区代理：显式设置优先；未设置时自动使用 detailV（若其实现协议）
    public weak var contentDelegate:ScreenPopupDelegate?

    /// 内容视图
    private weak var detailV:UIView?
    /// 顶部 view
    private weak var headerView:UIView?
    /// 顶部占用的高度（cover 类型为 0）
    private var headerH:CGFloat = 0
    /// 底部留白
    private var btmHeight:CGFloat = 0
    /// 圆角
    private var cornerSize:CGSize = .zero
    /// 内容区创建时是否等于屏幕宽度（用于旋转后宽度跟随）
    private var isDetailFullWidth:Bool = false
    /// 内容区期望高度（不受当前容器夹取影响，旋转回来后可以恢复）
    private var desiredDetailHeight:CGFloat = 0
    /// will 阶段暂存的内容区变化，did 阶段回传
    private var pendingContentChange:ScreenPopupLayoutChange?
    /// 上次应用圆角时的尺寸，避免重复创建 mask
    private var lastCornerSize:CGSize = .zero

    open override func layoutSubviews() {
        super.layoutSubviews()
        guard cornerSize != .zero else { return }
        guard bounds.size != lastCornerSize else { return }
        lastCornerSize = bounds.size
        let corners:UIRectCorner = (kDevice.isPad && width < kScreen.width) ? .allCorners : [.topLeft,.topRight]
        cornerRadii(size: cornerSize, corners: corners)
    }

    ///创建view
    public func createView(_ detailV:UIView, headerInfo:ScreenPopupSheetBorder.HeaderInfo?, cover:Bool, hidden:Bool, cornerSize:CGSize, btmHeight:CGFloat,
                                bgColor:UIColor) {
        
        let detailH:CGFloat = detailV.height

        var headerH:CGFloat = 0
        if let headerInfo, headerInfo.type == .vertical {
            headerH =  headerInfo.view.height
        }

        self.frame = CGRect.init(x: 0, y: kScreen.height, width: detailV.width, height: detailH + headerH + btmHeight)
        self.backgroundColor = bgColor

        self.detailV = detailV
        self.headerView = headerInfo?.view
        self.headerH = headerH
        self.btmHeight = btmHeight
        self.cornerSize = cornerSize
        self.isDetailFullWidth = kScreen.width > 0 && detailV.width >= kScreen.width - 1
        self.desiredDetailHeight = detailH
        
        if let headerInfo {
            /// 放这里说明要用到当前弹窗的高度
            headerInfo.view.frame = CGRect(x: 0, y: 0, width: detailV.width, height: headerInfo.view.height);
            self.addSubview(headerInfo.view)
            if let headerView = headerInfo.view as? SheetBorderSliderHeader {
                headerView.panLinkView = self
                headerView.dismissClosure = { [weak self] in
                    self?.dismissView()
                }
            }
        }
        

        detailV.y = headerH
        self.addSubview(detailV)
        self.sendSubviewToBack(detailV)

        self.popView = ScreenPopupManager.shared.createMutiPopupView(popupView: self, mainView: detailV, action: (hidden ? #selector(dismissView) : nil), target: (hidden ? self : nil), cover: cover)
        /// sheet 自己处理整体尺寸变化
        self.popView?.popupDelegate = self
        /// 内容区若实现协议，自动接收尺寸回传
        if self.contentDelegate == nil {
            self.contentDelegate = detailV as? ScreenPopupDelegate
        }
        
    }
    
    @objc fileprivate func dismissView(){
        self.dismissSheetBorderView(animation: true)
    }
    
    public func dismissSheetBorderView(animation:Bool) {
        self.endEditing(true)
        self.dimissBlock?()
        self.popView?.dismiss(animation: animation)
    }
    
    public func showView(animation:Bool = true, hitThrough:Bool = false){
        self.popView?.show(animation: .enterFromBottom(), through: hitThrough, showCompletion: nil, dismissCompletion: nil)
    }

    // MARK: - ScreenPopupDelegate

    /// 作为弹窗整体接收尺寸变化：宽高、位置、内部内容区同步重排
    public func screenPopupWillChange(_ change: ScreenPopupLayoutChange) -> CGRect? {
        guard let detailV else { return nil }
        let containerSize = change.containerSize
        let oldSheetWidth = change.previousFrame.width
        let newWidth: CGFloat = isDetailFullWidth
            ? containerSize.width
            : min(oldSheetWidth > 0 ? oldSheetWidth : width, containerSize.width)

        /// 头部跟随宽度
        if let headerView {
            headerView.frame = CGRect(x: 0, y: 0, width: newWidth, height: headerView.height)
        }

        let maxContentH = max(0, containerSize.height - headerH - btmHeight)
        let oldContentFrame = detailV.frame
        let baseContentH = desiredDetailHeight > 0 ? desiredDetailHeight : oldContentFrame.height
        let proposedContentFrame = CGRect(x: 0, y: headerH, width: newWidth, height: min(baseContentH, maxContentH))
        let availableContentSize = CGSize(width: newWidth, height: maxContentH)
        let oldAvailableContentSize = CGSize(width: oldSheetWidth,
                                             height: max(0, change.oldContainerSize.height - headerH - btmHeight))
        let contentChange = ScreenPopupLayoutChange(oldContainerSize: oldAvailableContentSize,
                                                    containerSize: availableContentSize,
                                                    previousFrame: oldContentFrame,
                                                    frame: proposedContentFrame,
                                                    animationDuration: change.animationDuration)

        /// 1. 内容区代理优先；返回 nil 时继续尝试 Auto Layout 测量
        var contentFrame = contentDelegate?.screenPopupWillChange(contentChange)
        if let customFrame = contentFrame {
            /// 代理返回的高度记为新的期望高度，容器放不下时只做显示夹取
            desiredDetailHeight = max(customFrame.height, 0)
        } else if detailV.translatesAutoresizingMaskIntoConstraints == false {
            /// 2. Auto Layout 内容：按新宽度重新测量高度
            let fit = detailV.systemLayoutSizeFitting(CGSize(width: newWidth, height: UIView.layoutFittingCompressedSize.height),
                                                      withHorizontalFittingPriority: .required,
                                                      verticalFittingPriority: .fittingSizeLevel)
            if fit.height > 1, fit.height.isFinite {
                desiredDetailHeight = fit.height
                contentFrame = proposedContentFrame
                contentFrame?.size.height = min(fit.height, maxContentH)
            }
        }
        /// 3. 都没给出可用结果时保留原高度
        var finalContentFrame = contentFrame ?? proposedContentFrame

        finalContentFrame.origin.x = 0
        finalContentFrame.origin.y = headerH
        if finalContentFrame.width <= 0 {
            finalContentFrame.size.width = newWidth
        }
        finalContentFrame.size.width = min(max(finalContentFrame.width, 0), newWidth)
        finalContentFrame.size.height = min(max(finalContentFrame.height, 0), maxContentH)
        detailV.frame = finalContentFrame
        detailV.layoutIfNeeded()

        let newHeight = min(finalContentFrame.height + headerH + btmHeight, containerSize.height)
        pendingContentChange = ScreenPopupLayoutChange(oldContainerSize: oldAvailableContentSize,
                                                       containerSize: availableContentSize,
                                                       previousFrame: oldContentFrame,
                                                       frame: finalContentFrame,
                                                       animationDuration: change.animationDuration)
        /// 与显示动画保持一致：全宽贴左；iPad 非全宽右对齐 10，其它贴左
        let x: CGFloat
        if isDetailFullWidth {
            x = 0
        } else if kDevice.isPad && newWidth != containerSize.width {
            x = containerSize.width - newWidth - 10
        } else {
            x = 0
        }
        return CGRect(x: x, y: containerSize.height - newHeight, width: newWidth, height: newHeight)
    }

    /// 弹窗整体落位后，把内容区最终 frame 回传给调用方
    public func screenPopupDidChange(_ change: ScreenPopupLayoutChange) {
        if let pendingContentChange {
            self.pendingContentChange = nil
            contentDelegate?.screenPopupDidChange(pendingContentChange)
        }
    }

    public func screenPopupDidShow() {
        contentDelegate?.screenPopupDidShow()
    }

    public func screenPopupDidDismiss() {
        contentDelegate?.screenPopupDidDismiss()
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
    ///   - clickThrough: 点击透传
    ///   - dismiss: 开始隐藏的回调
    @discardableResult
    public func animationShow(cover:Bool = true,
                              header info:ScreenPopupSheetBorder.HeaderInfo? = nil,
                              autoHidden hidden:Bool = true,
                              bottomHeight:CGFloat = max(kSafeBtmH, 20),
                              backgroundColor:UIColor = .white,
                              cornerSize:CGSize = CGSize(width: 10, height: 10),
                              clickThrough:Bool = false,
                              dismiss:DismissClosure? = nil) -> ScreenPopupSheetBorder?{
        
        let borderV = ScreenPopupManager.getMutiPopupView(popupV: self)
        guard let bdV = borderV as? ScreenPopupSheetBorder else {
            /// 没值
            let borderView = ScreenPopupSheetBorder.init(frame: CGRect.zero)
            borderView.dimissBlock = dismiss
            borderView.createView(self, headerInfo: info, cover: cover, hidden: hidden, cornerSize: cornerSize, btmHeight: bottomHeight, bgColor:backgroundColor)
            borderView.showView(animation: true, hitThrough: clickThrough)
            return borderView
        }
        ///到这就是有值了
        return bdV
    }
    
    /// 隐藏弹窗
    public func animationDismiss(animation:Bool = true){
        let borderV = ScreenPopupManager.getMutiPopupView(popupV: self)
        guard let borderView = borderV as? ScreenPopupSheetBorder else {
            return
        }
        borderView.dismissSheetBorderView(animation: animation)
    }
    
    
    public func checkAnimationPopupView() -> Bool {
        let borderV = ScreenPopupManager.getMutiPopupView(popupV: self)
        guard let _ = borderV as? ScreenPopupSheetBorder else {
            return false
        }
        return true
    }
    
    
}


