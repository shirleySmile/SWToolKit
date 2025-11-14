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

    init(frame: CGRect, outlink: UIView) {
        super.init(frame: frame)
        self.isHidden = true
        self.clipsToBounds = true
        self.isUserInteractionEnabled = true
        
        self.addSubview(outlink)
        self.outlinkView = outlink
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 显示
    func show(animation aType: ScreenPopupAnimationType) {
        self.backgroundColor = bgColor?.withAlphaComponent(0.2)
        self.animationType = aType
        self.showAnimationView()
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
        case .centerAndEnlarged:
            UIView.animate(withDuration: 0.25) {
                outlinkView.alpha = 0
                outlinkView.transform = .init(scaleX: 0.1, y: 0.1)
            } completion: { [weak self] finish in
                self?.dismissCallback()
            }
        case .enterFromTop:
            UIView.animate(withDuration: 0.25) {
                var tempF = outlinkView.frame
                tempF.origin.y = (-tempF.height - 5)
                outlinkView.frame = tempF
            } completion: { [weak self] finish in
                self?.dismissCallback()
            }
        case .enterFromBottom:
            UIView.animate(withDuration: 0.25) {
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
    public func showAnimationView() {
        guard let outlinkView else {
            self.dismissCallback()
            return
        }
        self.alpha = 0
        self.isHidden = false
        let viewH = self.height
        switch animationType {
        case .centerAndEnlarged:
            outlinkView.center = CGPoint.init(x: self.width/2.0, y: self.height/2.0)
            outlinkView.transform = .init(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) { [weak self] in
                self?.alpha = 1.0
                outlinkView.transform = .identity
            } completion: { finish in
                
            }
        case .enterFromTop:
            outlinkView.frame = .init(origin: .init(x: outlinkView.x, y: 0), size: outlinkView.size)
            self.alpha = 1.0
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseIn) {
                var tempF2 = outlinkView.frame
                tempF2.origin.y = 0
                outlinkView.frame = tempF2
            } completion: { finish in
                
            }
        case .enterFromBottom:
            let pointX:CGFloat = (kDevice.isPad && (self.width != outlinkView.width)) ? (self.width - outlinkView.width - 10) : 0
            outlinkView.frame = .init(origin: .init(x: pointX, y: self.height + 5), size: outlinkView.size)
            self.alpha = 1.0
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseIn) {
                var tempF = outlinkView.frame
                tempF.origin.y = (viewH-tempF.height)
                outlinkView.frame = tempF
            } completion: { finish in
               
            }
        case .none:
            self.alpha = 1.0
        }
    
    }

    
    
    /// 关闭子视图后的回调用
    private func dismissCallback() {
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


