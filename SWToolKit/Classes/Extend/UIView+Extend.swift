//
//  UIView+Extend.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/14.
//

import Foundation
import UIKit

/// 与UIView相关的方法
extension UIView {
    
    /// 给view的某个角切圆角
    /// - Parameters:
    ///   - size: 大小
    ///   - corners: 方向
    public func cornerRadii(size:CGSize, corners:UIRectCorner) {
        let maskPath = UIBezierPath.init(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: size)
        let maskLayer = CAShapeLayer.init()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.cgPath
        self.layer.mask = maskLayer
    }
    
    
    /// view的四周圆角
    /// - Parameter radius: 弧度
    /// - Returns: UIView
    @discardableResult
    public func layerCorner(radius:CGFloat) -> Self{
        self.layer.masksToBounds = true
        self.layer.cornerRadius = radius
        return self
    }
    
    /// view的边框
    /// - Parameters:
    ///   - width: 边框宽度
    ///   - color: 边框颜色
    /// - Returns: UIView
    @discardableResult
    public func layerBorder(width:CGFloat, color:UIColor) -> Self{
        self.layer.borderWidth = width
        self.layer.borderColor = color.cgColor
        return self
    }
    
    
    
    public func removeAllSubviews() {
        self.subviews.forEach { subV in
            subV.removeFromSuperview()
        }
    }
    

    /// 添加阴影
    /// - Parameters:
    ///   - color: 阴影颜色
    ///   - opacity: 阴影透明度
    ///   - radius: 阴影半径
    ///   - rectEdge: 设置哪一侧的阴影
    ///   - width: 阴影的宽度
    public func shadow(color:UIColor, opacity:Float, radius:Float, rectEdge:UIRectEdge, width:Float) {
        self.layoutIfNeeded()
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = CGFloat(radius)
        self.layer.shadowOffset = CGSize(width: 0, height: 0)

        var originX = 0.0
        var originY = 0.0
        var originW = self.bounds.width
        var originH = self.bounds.height
        let pathWidth = CGFloat(width)
        
        switch rectEdge.rawValue {
        case 1: ///top
            originY = originY - pathWidth
        case 2: ///left
            originX = originX - pathWidth
        case 3: ///3:top+left
            originY = originY - pathWidth
            originX = originX - pathWidth
        case 4: ///bottom
            originH = originH + pathWidth
        case 5: ///bottom+top
            originY = originY - pathWidth
            originH = originH + pathWidth*2
        case 6: ///left+bottom
            originX = originX - pathWidth
            originH = originH + pathWidth
        case 7: ///top+bottom+left
            originY = originY - pathWidth
            originH = originH + pathWidth*2
            originX = originX - pathWidth
            originW = originW + pathWidth
        case 8: ///right
            originW = originW + pathWidth
        case 9: ///right+top
            originW = originW + pathWidth
            originY = originY - pathWidth
        case 10: ///right+left
            originX = originX - pathWidth
            originW = originW + pathWidth*2
        case 11: ///right+top+left
            originY = originY - pathWidth
            originX = originX - pathWidth
            originW = originW + pathWidth*2
            originH = originH + pathWidth
        case 12: ///right+bottom
            originW = originW + pathWidth
            originH = originH + pathWidth
        case 13: ///right+bottom+top
            originY = originY - pathWidth
            originH = originH + pathWidth*2
            originW = originW + pathWidth
        case 14: ///right+left+bottom
            originX = originX - pathWidth
            originW = originW + pathWidth*2
            originH = originH + pathWidth
        default: ///all
            originX = originX - pathWidth
            originY = originY - pathWidth
            originH = originH + pathWidth*2
            originW = originW + pathWidth*2
        }
        
        let shadowRect = CGRect(x: originX, y: originY, width:originW, height:originH)
        let path = UIBezierPath.init(roundedRect: shadowRect, cornerRadius: CGFloat(radius))
        self.layer.shadowPath = path.cgPath
    }

}




public enum GradientDirection {
    case Horizontal //从左到右
    case Vertical //从上到下
    case LeftUpToRightDown //从左上角到右下角
    case LeftDownToRightUp //从左下角到右上角
}

extension UIView {
    
    
    ///将当前视图转为UIImage
    public func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
    

}





//MARK: 添加点击事件
extension UIView {
    
    private struct tapViewAssociatedKeys {
        @MainActor static var tapClosure = "tapClosure"
    }
    
    ///点击事件的回调
    private var tapClosure:(()->Void)?{
        set{
            objc_setAssociatedObject(self, &tapViewAssociatedKeys.tapClosure, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        get{
            return objc_getAssociatedObject(self, &tapViewAssociatedKeys.tapClosure) as? (()->Void)
        }
    }
    
    ///点击事件，返回指定的view
    @discardableResult
    public func tapView<T:UIView>(_ tap: @escaping ()->Void) -> T {
        tapClosure = tap
        if let controlV = self as? UIControl {
            controlV.addTarget(self, action: #selector(viewWhenTapControlBlock(control:)), for: .touchUpInside)
        }
        else{
            let tap = UITapGestureRecognizer.init(target: self, action: #selector(viewWhenTapGRBlock(tapGR:)))
            tap.numberOfTapsRequired = 1
            tap.cancelsTouchesInView = false
            tap.delaysTouchesBegan = false
            tap.delaysTouchesEnded = false
            self.addGestureRecognizer(tap)
        }
        return self as! T
    }
    
    @discardableResult
    public func tapView<T:UIView>(target:Any?, action:Selector) -> T{
        if let controlV = self as? UIControl {
            controlV.addTarget(target, action: action, for: .touchUpInside)
        }
        else{
            let tap = UITapGestureRecognizer.init(target: target, action: action)
            tap.numberOfTapsRequired = 1
            tap.cancelsTouchesInView = false
            tap.delaysTouchesBegan = false
            tap.delaysTouchesEnded = false
            self.addGestureRecognizer(tap)
        }
        return self as! T
    }
   
    // 点击control
    @objc private func viewWhenTapControlBlock(control:UIControl) {
        self.tapClosure?()
    }
    
    @objc private func viewWhenTapGRBlock(tapGR:UITapGestureRecognizer) {
        if tapGR.view == self {
            self.tapClosure?()
        }
    }
}

//获取控制器
public extension UIView{
    func responseVc() -> UIViewController?{
        var nexResponser :UIResponder? = self
        repeat {
            nexResponser = nexResponser?.next
            if let nexResponser = nexResponser as? UIViewController {
                return nexResponser
            }
        }while nexResponser != nil
        
        return nil
    }
    
}
