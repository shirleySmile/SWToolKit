//
//  ScreenPopupSheetBorder.swift
//  SWToolKit
//
//  Created by shirley on 2022/5/25.
//

import Foundation
import UIKit
import SnapKit

public typealias DismissClosure = () -> Void



/// 带下滑手势的View
open class SheetBorderSliderHeader: UIView {
    
    private var originPointY:CGFloat = 0
    fileprivate var dismissClosure:(()->Void)?
    fileprivate var panLinkView:UIView? {
        didSet {
            if let panLinkView {
                panLinkView.layoutIfNeeded()
                originPointY = kScreen.height-panLinkView.height
            }
        }
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
        super.init(frame: frame)
        
        self.backgroundColor = .yellow
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
        if pointY >= originPointY {
//        if translation.y > 0 {
            // 将视图的位置根据手势的移动进行调整
            if let _ = gestureRecognizer.view {
                linkView.center = CGPoint(x: linkView.center.x, y: centerY)
            }
        }
        
        // 当手势结束时，实现反弹效果
        if gestureRecognizer.state == .ended {
            if let _ = gestureRecognizer.view {
                if linkView.origin.y - (kScreen.height - linkView.height) > (linkView.height * 1.0 / 3.0){
                    self.dismiss()
                }else{
                    let originY = self.getOriginPointY()
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
    
    private func getOriginPointY() -> CGFloat {
        guard self.originPointY <= 0 else {
            return self.originPointY
        }
        self.originPointY = kScreen.height - (panLinkView?.height ?? kScreen.height)
        return self.originPointY
    }
    
    
}



///弹出view的包边
open class ScreenPopupSheetBorder: UIView {

    public enum HeaderType {
        /// 内容视图的顶部
        case vertical
        /// 遮盖在内容视图的顶部
        case cover
    }
    
    public struct HeaderInfo {
        var view:UIView
        var type:HeaderType = .vertical
        
        public init(view: UIView, type: HeaderType) {
            self.view = view
            self.type = type
        }
    }
    
    ///dimiss回调
    public var dimissBlock:DismissClosure?
    private(set) weak var popView:ScreenPopupOnePiece?
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

        if !cornerSize.equalTo(.zero){
            self.cornerRadii(size: cornerSize, corners: [.topLeft,.topRight])
            
            if kDevice.isPad && detailV.width < kScreen.width {
                self.cornerRadii(size: cornerSize, corners: .allCorners)
            }
        }

        self.popView = ScreenPopupManager.shared.createMutiPopupView(popupView: self, mainView: detailV, action: (hidden ? #selector(dismissView) : nil), target: (hidden ? self : nil), cover: cover)
        
    }
    
    @objc fileprivate func dismissView(){
        self.dismissSheetBorderView(animation: true)
    }
    
    public func dismissSheetBorderView(animation:Bool) {
        self.endEditing(true)
        self.dimissBlock?()
        self.popView?.dismiss(animation: animation)
    }
    
    public func showView(animation:Bool = true){
        self.popView?.show(animation: .enterFromBottom())
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
                              header info:ScreenPopupSheetBorder.HeaderInfo? = nil,
                              autoHidden hidden:Bool = true,
                              bottomHeight:CGFloat = max(kSafeBtmH, 20),
                              backgroundColor:UIColor = .white,
                              cornerSize:CGSize = CGSize(width: 10, height: 10),
                              dismiss:DismissClosure? = nil) -> ScreenPopupSheetBorder?{
        
        let borderV = ScreenPopupManager.getMutiPopupView(popupV: self)
        guard let bdV = borderV as? ScreenPopupSheetBorder else {
            /// 没值
            let borderView = ScreenPopupSheetBorder.init(frame: CGRect.zero)
            borderView.dimissBlock = dismiss
            borderView.createView(self, headerInfo: info, cover: cover, hidden: hidden, cornerSize: cornerSize, btmHeight: bottomHeight, bgColor:backgroundColor)
            borderView.showView(animation: true)
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


