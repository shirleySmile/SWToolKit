//
//  ScreenPopupOnePriceView.swift
//  Pods
//
//  Created by muwa on 2025/11/12.
//


import UIKit

/// 屏幕弹窗的 View
class ScreenPopupBackgroundView:HitThroughView {
    
    static let viewTag:Int = 123456789
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.tag = ScreenPopupBackgroundView.viewTag
        /// 跟随 window / 外部容器的尺寸变化（旋转、iPad 分屏、台前调度）
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


protocol ScreenPopupOnePieceDelegate:NSObject {
    /// 关闭弹窗
    func screenPopop(close view: ScreenPopupOnePiece)
}

/// 每个弹窗的控制视图
class ScreenPopupOnePiece: UIView {
    
    /// 显示动画
    private var animationType:ScreenPopupAnimationType = .none
    /// 外联 view  (当前 view 上的视图， 动画操作此视图)
    private(set) weak var outlinkView:UIView?
    /// 主图（项目中主要显示内容的视图）
    weak var subMainView:UIView?
    
    weak var delegate:ScreenPopupOnePieceDelegate?
    /// 背景色
    var bgColor:UIColor?
    /// 自定义key
    var customKey:String = String.random(num: 10)
    
    var dismissCompletion:(()->Void)? = nil
    /// 一次完整的关闭（避免重复触发回调）
    private var isDismissed:Bool = false
    /// 点击穿透
    var hitThrough:Bool = false
    /// 尺寸变化 / 生命周期代理（weak，避免循环引用）
    weak var popupDelegate: ScreenPopupDelegate?
    /// 创建时的容器尺寸
    private var originalContainerSize: CGSize = .zero
    /// 创建时的 outlink frame
    private var originalFrame: CGRect = .zero
    /// outlink 的归一化中心（相对容器）
    private var layoutAnchor: CGPoint = .init(x: 0.5, y: 0.5)
    /// 上一次的容器尺寸，用于判断是否真的发生了尺寸变化
    private var lastContainerSize: CGSize = .zero
    
    init(frame: CGRect, outlink: UIView) {
        super.init(frame: frame)
        self.isHidden = true
        self.clipsToBounds = true
        self.isUserInteractionEnabled = true
        /// 跟随背景层的尺寸变化
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        self.originalContainerSize = frame.size
        self.lastContainerSize = frame.size
        self.originalFrame = outlink.frame
        if frame.width > 0, frame.height > 0 {
            self.layoutAnchor = .init(x: outlink.frame.midX / frame.width,
                                      y: outlink.frame.midY / frame.height)
        }

        self.addSubview(outlink)
        self.outlinkView = outlink
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = bounds.size
        guard size.width > 0, size.height > 0 else { return }
        guard size != lastContainerSize else { return }
        let oldSize = lastContainerSize
        lastContainerSize = size
        refreshLayout(oldContainerSize: oldSize, newContainerSize: size)
    }
    
    /// 显示
    func show(animation aType: ScreenPopupAnimationType, through:Bool = false, showCompletion:(()->Void)?, dismissCompletion:(()->Void)?) {
        /// 尊重调用方传入的遮罩色及其透明度（原实现强制覆盖为 0.2 导致 cover 参数失效）
        self.backgroundColor = bgColor
        self.animationType = aType
        self.hitThrough = through
        self.dismissCompletion = dismissCompletion
        self.showAnimationView(showCompletion)
    }
    
    /// 关闭弹窗 ---从上往下退出
    /// animation: 如果显示时有动画，关闭时是否播放动画
    func dismiss(animation:Bool){
        /// 不播放动画，直接关闭视图
        guard animation else {
            self.dismissCallback()
            return
        }
        /// 播放动画后再关闭
        self.dismissAnimationView()
    }
       
    
    /// 设置可以点击视图区域外
    func outside(_ outsizeAction:ScreenPopupAction? = nil) {
        if let outsizeAction {
            let tap = UITapGestureRecognizer.init(target: outsizeAction.target, action: outsizeAction.action)
            tap.delegate = self
            self.addGestureRecognizer(tap)
        }
        else{
            let tap = UITapGestureRecognizer.init(target: self, action: #selector(clickHiddenView(tapGR:)))
            tap.delegate = self
            self.addGestureRecognizer(tap)
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitV = super.hitTest(point, with: event)
        if hitThrough, hitV == self {
            return nil
        }
        return hitV
    }
}



extension ScreenPopupOnePiece {
    
    /// 关闭视图
    private func dismissAnimationView() {
        guard let outlinkView else {
            self.dismissCallback()
            return
        }
        let viewH = self.height
        switch animationType {
        case .enterFromCenter(let enlarged):
            if enlarged {
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
                    outlinkView.alpha = 0
                    outlinkView.transform = .init(scaleX: 0.1, y: 0.1)
                } completion: { [weak self] finish in
                    self?.dismissCallback()
                }
            } else {
                outlinkView.alpha = 0
                self.dismissCallback()
            }
        case .enterFromTop:
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
                var tempF = outlinkView.frame
                tempF.origin.y = (-tempF.height - 5)
                outlinkView.frame = tempF
            } completion: { [weak self] finish in
                self?.dismissCallback()
            }
        case .enterFromBottom:
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
                var tempF = outlinkView.frame
                tempF.origin.y = (viewH + 5)
                outlinkView.frame = tempF
            } completion: { [weak self] finish in
                self?.dismissCallback()
            }
        case .none:
            self.dismissCallback()
        }
    }

    
    /// view显示动画 ---从下往上进入
    /// - Parameters:
    ///   - popupView: 弹窗的view
    ///   - animation: 是否有动画
    public func showAnimationView(_ completion:(()->Void)?) {
        guard let outlinkView else {
            self.dismissCallback()
            return
        }
        self.alpha = 0
        self.isHidden = false
        let viewH = self.height
        /// 动画完成：先通知代理，再执行外部 completion
        let didShow: () -> Void = { [weak self] in
            self?.popupDelegate?.screenPopupDidShow()
            completion?()
        }
        switch animationType {
        case .enterFromCenter(let enlarged):
            outlinkView.center = CGPoint.init(x: self.width/2.0, y: self.height/2.0)
            if enlarged {
                outlinkView.transform = .init(scaleX: 0.1, y: 0.1)
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) { [weak self] in
                    self?.alpha = 1.0
                    outlinkView.transform = .identity
                } completion: { finish in
                    didShow()
                }
            } else {
                self.alpha = 1.0
                didShow()
            }
        case .enterFromTop(let spring):
            outlinkView.frame = .init(origin: .init(x: outlinkView.x, y: -(outlinkView.height + 5)), size: outlinkView.size)
            self.alpha = 1.0
            if spring {
                UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn) {
                    var tempF2 = outlinkView.frame
                    tempF2.origin.y = 0
                    outlinkView.frame = tempF2
                } completion: { _ in
                    didShow()
                }
            } else {
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
                    var tempF2 = outlinkView.frame
                    tempF2.origin.y = 0
                    outlinkView.frame = tempF2
                } completion: { _ in
                    didShow()
                }
            }
        case .enterFromBottom(let spring):
            let pointX:CGFloat = (kDevice.isPad && (self.width != outlinkView.width)) ? (self.width - outlinkView.width - 10) : 0
            outlinkView.frame = .init(origin: .init(x: pointX, y: self.height + 5), size: outlinkView.size)
            self.alpha = 1.0
            if spring {
                UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn) {
                    var tempF = outlinkView.frame
                    tempF.origin.y = (viewH-tempF.height)
                    outlinkView.frame = tempF
                } completion: { _ in
                    didShow()
                }
            } else {
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
                    var tempF = outlinkView.frame
                    tempF.origin.y = (viewH-tempF.height)
                    outlinkView.frame = tempF
                } completion: { _ in
                    didShow()
                }
            }
        case .none:
            self.alpha = 1.0
            didShow()
        }
    
    }

    
    
    /// 关闭子视图后的回调用
    private func dismissCallback() {
        /// 防止外部重复 dismiss / 手势与点击叠加导致代理收到多次回调
        guard !isDismissed else { return }
        isDismissed = true
        self.popupDelegate?.screenPopupDidDismiss()
        self.dismissCompletion?()
        self.subMainView?.removeFromSuperview()
        self.subMainView = nil
        self.outlinkView?.removeFromSuperview()
        self.outlinkView?.removeFromSuperview()
        self.delegate?.screenPopop(close: self)
    }
    
    
    ///点击事件
    @objc private func clickHiddenView(tapGR:UITapGestureRecognizer) {
        let tapV = tapGR.view
        guard let tapView = (tapV as? ScreenPopupOnePiece) else {
            return
        }
        debugPrint("==SWToolKit==" + "failed \(String(describing: tapView))")
        self.dismissAnimationView()
    }

}



extension ScreenPopupOnePiece: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let _ = touch.view as? ScreenPopupOnePiece else{
            return false
        }
        return true
    }
}



// MARK: - 尺寸变化

private extension ScreenPopupOnePiece {

    /// 容器尺寸变化后重新落位，并把新尺寸回传给代理
    func refreshLayout(oldContainerSize: CGSize, newContainerSize: CGSize) {
        guard let outlinkView else { return }
        let previousFrame = outlinkView.frame
        let proposedFrame = defaultFrame(in: newContainerSize)
        let duration = currentTransitionDuration()

        let change = ScreenPopupLayoutChange(oldContainerSize: oldContainerSize,
                                             containerSize: newContainerSize,
                                             previousFrame: previousFrame,
                                             frame: proposedFrame,
                                             animationDuration: duration)
        /// 代理明确返回 frame 时直接采用（精确覆盖）；否则用库计算值并夹取到容器内
        let finalFrame: CGRect
        if let delegateFrame = popupDelegate?.screenPopupWillChange(change), isUsable(delegateFrame) {
            finalFrame = delegateFrame
        } else {
            finalFrame = clamp(proposedFrame, in: newContainerSize)
        }

        /// 在系统的旋转/布局事务里直接落位，跟随系统过渡动画
        outlinkView.frame = finalFrame
        outlinkView.layoutIfNeeded()

        let finalChange = ScreenPopupLayoutChange(oldContainerSize: oldContainerSize,
                                                  containerSize: newContainerSize,
                                                  previousFrame: previousFrame,
                                                  frame: finalFrame,
                                                  animationDuration: duration)
        popupDelegate?.screenPopupDidChange(finalChange)
    }

    /// 按动画类型计算默认落位 frame
    func defaultFrame(in container: CGSize) -> CGRect {
        guard let outlinkView else { return .zero }
        var frame = outlinkView.frame
        let isFullWidth = originalContainerSize.width > 0
            && originalFrame.width >= originalContainerSize.width - 1

        switch animationType {
        case .none:
            /// 记录归一化中心；原来全宽的继续跟随宽度，非全宽保持原宽并夹取
            if isFullWidth {
                frame.size.width = container.width
                frame.origin.x = 0
            } else {
                let width = min(originalFrame.width, container.width)
                frame.size.width = width
                let anchorX = layoutAnchor.x.isFinite ? layoutAnchor.x : 0.5
                frame.origin.x = anchorX * container.width - width / 2
            }
            let height = min(originalFrame.height, container.height)
            frame.size.height = height
            let anchorY = layoutAnchor.y.isFinite ? layoutAnchor.y : 0.5
            frame.origin.y = anchorY * container.height - height / 2
        case .enterFromCenter:
            frame.size.width = min(frame.width, container.width)
            frame.size.height = min(frame.height, container.height)
            frame.origin.x = (container.width - frame.width) / 2
            frame.origin.y = (container.height - frame.height) / 2
        case .enterFromTop:
            if isFullWidth {
                frame.size.width = container.width
                frame.origin.x = 0
            } else {
                frame.size.width = min(frame.width, container.width)
            }
            frame.origin.y = 0
        case .enterFromBottom:
            if isFullWidth {
                frame.size.width = container.width
                frame.origin.x = 0
            } else {
                frame.size.width = min(frame.width, container.width)
                if kDevice.isPad && frame.width != container.width {
                    frame.origin.x = container.width - frame.width - 10
                }
            }
            frame.origin.y = container.height - frame.height
        }
        return frame
    }

    /// 代理返回的 frame 是否可用（坐标与尺寸必须有限且尺寸大于 0）
    func isUsable(_ frame: CGRect) -> Bool {
        frame.origin.x.isFinite && frame.origin.y.isFinite
            && frame.size.width.isFinite && frame.size.height.isFinite
            && frame.width > 0 && frame.height > 0
    }

    /// 保证 frame 不超出容器
    func clamp(_ frame: CGRect, in container: CGSize) -> CGRect {
        var result = frame
        result.size.width = min(result.size.width, container.width)
        result.size.height = min(result.size.height, container.height)
        result.origin.x = min(max(result.origin.x, 0), max(0, container.width - result.size.width))
        result.origin.y = min(max(result.origin.y, 0), max(0, container.height - result.size.height))
        return result
    }

    /// 当前系统过渡动画时长；拿不到时返回 0（表示不做动画）
    func currentTransitionDuration() -> TimeInterval {
        let inherited = UIView.inheritedAnimationDuration
        if inherited > 0 { return inherited }
        if let coordinator = kCurrentVC?.transitionCoordinator, coordinator.isAnimated {
            return coordinator.transitionDuration
        }
        return 0
    }
}



