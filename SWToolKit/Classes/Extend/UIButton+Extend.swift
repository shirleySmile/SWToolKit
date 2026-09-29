//
//  UIButton+Extend.swift
//  SWToolKit
//
//  Created by shirley on 2023/3/7.
//

import Foundation
import UIKit

public enum ButtonImageAndTitlePossitionStyle:Int{
    case normal         = 0 //正常
    case imageIsLeft    = 1 //左图右文
    case imageIsRight   = 2 //左文右图
    case imageIsTop     = 3 //上图下文
    case imgageIsBottom = 4 //上文下图
}

public struct ButtonImageAndTitleParam{
    var image:UIImage?
    var title:String
    var style:ButtonImageAndTitlePossitionStyle = .normal
    var spacing:CGFloat = 0
    var state:UIControl.State = .normal
    var isSureTitleCompress:Bool = false
    public init(image: UIImage? , title: String, style: ButtonImageAndTitlePossitionStyle = .normal, spacing: CGFloat = 0, state: UIControl.State = .normal, isSureTitleCompress: Bool = false) {
        self.image = image
        self.title = title
        self.style = style
        self.spacing = spacing
        self.state = state
        self.isSureTitleCompress = isSureTitleCompress
    }
}
public extension UIButton {
    
    /// 设置label相对于图片的位置
    /// - Parameters:
    ///   - anImage: 按钮图片
    ///   - title: 标题
    ///   - style: label相对于图片的位置（上下左右）
    ///   - spacing: 文字和图片的间隔
    ///   - state: UIControl.State
    ///   - isSureTitleCompress: 该参数已不生效（配置化布局下标题压缩由系统自动处理，保留仅为兼容既有调用）
    func setImage(param:ButtonImageAndTitleParam){
        self.setImage(param.image, for: state)
        self.setTitle(param.title, for: state)
        positionLabelRespectToImage(style: param.style, spacing: param.spacing)
    }
    
    /// 统一使用 UIButtonConfiguration 布局
    /// iOS 15.0 起 imageEdgeInsets / titleEdgeInsets / titleRect(forContentRect:) 已弃用，
    /// 无论按钮是否已有 configuration，都通过 imagePlacement / imagePadding 控制图文排布，
    /// 标题压缩等场景由系统配置化布局自动处理
    private func positionLabelRespectToImage(style: ButtonImageAndTitlePossitionStyle = .normal, spacing: CGFloat = 0) {
        /// 保留当前标题颜色：无 configuration 的按钮应用 plain 配置后，
        /// 系统默认会把标题渲染为 tintColor，钉入原色避免视觉变化
        let titleColor = self.titleLabel?.textColor
        var config: UIButton.Configuration
        if let existConfig = self.configuration {
            config = existConfig
        } else {
            /// 无 configuration 的按钮创建中性配置：
            /// contentInsets 置零对齐旧版按钮默认内边距，背景置为透明避免引入新样式
            var plain = UIButton.Configuration.plain()
            plain.contentInsets = .zero
            plain.background = .clear()
            config = plain
        }
        if let titleColor {
            config.baseForegroundColor = titleColor
        }
        config.imagePadding = spacing
        switch style{
        case .imageIsLeft:
            config.imagePlacement = .leading
        case .imageIsRight:
            config.imagePlacement = .trailing
        case .imageIsTop:
            config.imagePlacement = .top
        case .imgageIsBottom:
            config.imagePlacement = .bottom
        default:
            config.imagePlacement = .leading
        }
        self.configuration = config
    }
}
