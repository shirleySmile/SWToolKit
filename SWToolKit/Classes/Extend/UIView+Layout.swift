//
//  UIView+Layout.swift
//  SWToolKit
//
//  Created by shirley on 2026/11/2.
//

import Foundation
import UIKit

/// 约束的方向（可组合）
public struct SWLayoutEdge: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let top    = SWLayoutEdge(rawValue: 1 << 0)
    public static let left   = SWLayoutEdge(rawValue: 1 << 1)
    public static let right  = SWLayoutEdge(rawValue: 1 << 2)
    public static let bottom = SWLayoutEdge(rawValue: 1 << 3)

    public static let horizontal: SWLayoutEdge = [.left, .right]
    public static let vertical: SWLayoutEdge = [.top, .bottom]
    public static let all: SWLayoutEdge = [.top, .left, .right, .bottom]
}

/// 简单的 Auto Layout 约束方法，替代 SnapKit 的常用写法
public extension UIView {

    /// 关闭 autoresizing 转换，开启 Auto Layout
    @discardableResult
    func sw_layoutReady() -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        return self
    }

    /// 与指定 view 的边缘对齐（left/right 为绝对方向，不随 RTL 镜像）
    /// - Parameters:
    ///   - edges: 需要对齐的边缘，默认四边
    ///   - view: 参照的 view
    ///   - insets: 内边距（正数表示向内缩）
    @discardableResult
    func sw_layoutEdges(_ edges: SWLayoutEdge = .all, equalTo view: UIView, insets: UIEdgeInsets = .zero) -> Self {
        sw_layoutReady()
        var constraints: [NSLayoutConstraint] = []
        if edges.contains(.top) {
            constraints.append(topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top))
        }
        if edges.contains(.left) {
            constraints.append(leftAnchor.constraint(equalTo: view.leftAnchor, constant: insets.left))
        }
        if edges.contains(.right) {
            constraints.append(rightAnchor.constraint(equalTo: view.rightAnchor, constant: -insets.right))
        }
        if edges.contains(.bottom) {
            constraints.append(bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom))
        }
        NSLayoutConstraint.activate(constraints)
        return self
    }

    /// 中心与指定 view 对齐
    @discardableResult
    func sw_layoutCenter(equalTo view: UIView, offset: CGPoint = .zero) -> Self {
        sw_layoutReady()
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset.x),
            centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: offset.y)
        ])
        return self
    }

    /// 水平中心与指定 view 对齐
    @discardableResult
    func sw_layoutCenterX(equalTo view: UIView, constant: CGFloat = 0) -> Self {
        sw_layoutReady()
        centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: constant).isActive = true
        return self
    }

    /// 垂直中心与指定 view 对齐
    @discardableResult
    func sw_layoutCenterY(equalTo view: UIView, constant: CGFloat = 0) -> Self {
        sw_layoutReady()
        centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: constant).isActive = true
        return self
    }

    /// 固定尺寸
    @discardableResult
    func sw_layoutSize(width: CGFloat, height: CGFloat) -> Self {
        sw_layoutReady()
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: width),
            heightAnchor.constraint(equalToConstant: height)
        ])
        return self
    }

    /// 固定尺寸
    @discardableResult
    func sw_layoutSize(_ size: CGSize) -> Self {
        return sw_layoutSize(width: size.width, height: size.height)
    }

    /// left 对齐到指定锚点
    @discardableResult
    func sw_layoutLeft(equalTo anchor: NSLayoutXAxisAnchor, constant: CGFloat = 0) -> Self {
        sw_layoutReady()
        leftAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        return self
    }

    /// right 对齐到指定锚点
    @discardableResult
    func sw_layoutRight(equalTo anchor: NSLayoutXAxisAnchor, constant: CGFloat = 0) -> Self {
        sw_layoutReady()
        rightAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        return self
    }

    /// 移除自身参与的所有约束（父视图及更上层祖先上的定位约束 + 自身上的宽高约束），用于重复布局的场景
    func sw_removeLayoutConstraints() {
        var ancestor = superview
        while let view = ancestor {
            let related = view.constraints.filter {
                $0.firstItem as? UIView === self || $0.secondItem as? UIView === self
            }
            NSLayoutConstraint.deactivate(related)
            ancestor = view.superview
        }
        /// 只移除自身的宽高约束，避免误删子视图的约束
        let own = constraints.filter {
            $0.firstItem as? UIView === self && $0.secondItem == nil
        }
        NSLayoutConstraint.deactivate(own)
    }
}
