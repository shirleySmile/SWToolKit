//
//  UIButton+Extend.swift
//  SWToolKit
//
//  Created by shirley on 2023/3/7.
//

import Foundation

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
//注意如果按钮是动态宽度的话，要先设置宽度
public extension UIButton {
     
    /// 设置label相对于图片的位置
    /// - Parameters:
    ///   - anImage: 按钮图片
    ///   - title: 标题
    ///   - style: label相对于图片的位置（上下左右）
    ///   - spacing: 文字和图片的间隔
    ///   - state: UIControl.State
    ///   - isSureTitleCompress: 是否明确文字被系统挤压，true：使用文字被压缩的调整模式，false：根据系统为文字分配的size自动适配（主要是了为了应对有些文字挤压的按钮被重复设置的情况）
    func setImage(param:ButtonImageAndTitleParam){
        self.setImage(param.image, for: state)
        self.setTitle(param.title, for: state)
        positionLabelRespectToImage(title: param.title, style: param.style, spacing: param.spacing, isSureTitleCompress: param.isSureTitleCompress)
    }
    
    private func positionLabelRespectToImage(title: String,style: ButtonImageAndTitlePossitionStyle = .normal,spacing: CGFloat = 0, isSureTitleCompress: Bool = false) {
        var isConfig = false
        if #available(iOS 15.0, *) {
            if self.configuration != nil{
                isConfig = true
            }
        }
        if isConfig{
            if #available(iOS 15.0, *) {
                var config = self.configuration
                config?.imagePadding = spacing
                switch style{
                case .imageIsLeft:
                    config?.imagePlacement = .leading
                    break
                case .imageIsRight:
                    config?.imagePlacement = .trailing
                    break
                case .imageIsTop :
                    config?.imagePlacement = .top
                    break
                case .imgageIsBottom:
                    config?.imagePlacement = .bottom
                    break
                default:
                    config?.imagePlacement = .leading
                    break
                }
                self.configuration = config
            } else {
                return
            }
        }else{
           updateBtnLayoutViews(title: title,style: style,spacing: spacing,isSureTitleCompress: isSureTitleCompress)
        }
        
         
        
    }
    
    private func updateBtnLayoutViews(title: String, style: ButtonImageAndTitlePossitionStyle = .normal,spacing: CGFloat = 0, isSureTitleCompress: Bool = false){
        self.layoutIfNeeded()//这一步很重要，否则如果UIButton通过约束布局会导致titleRect获取的rect不准
        let imageSize = self.imageView?.image?.size ?? .zero
        let titleSize = self.titleRect(forContentRect: self.frame).size//系统为titleLabel分配的size
        
        var titleNeedSize: CGSize = .zero//展示文字实际所需的size
        if let font = self.titleLabel?.font {
            titleNeedSize = title.size(withAttributes: [NSAttributedString.Key.font: font])
        }
        var isTitleCompress = false//文字是否被系统压缩
        if isSureTitleCompress {
            isTitleCompress = true
        } else if titleNeedSize.width > titleSize.width {
            isTitleCompress = true
        }
        
        switch (style){
        case .imageIsTop:
            let imageTop = -(titleSize.height/2 + spacing/2)
            let titleTop = imageSize.height/2 + spacing/2
            if isTitleCompress {
                let imageLeft = (self.bounds.size.width - imageSize.width) / 2
                self.imageEdgeInsets = UIEdgeInsets.init(top: imageTop, left: imageLeft, bottom: -imageTop, right: 0)
                self.titleEdgeInsets = UIEdgeInsets(top: titleTop, left: -imageSize.width, bottom: -titleTop, right: 0)
            } else {
                self.imageEdgeInsets = UIEdgeInsets(top: imageTop, left: titleSize.width/2, bottom: -imageTop, right: -titleSize.width/2)
                self.titleEdgeInsets = UIEdgeInsets(top: titleTop, left: -imageSize.width/2, bottom: -titleTop, right: imageSize.width/2)
            }
            
        case .imageIsLeft:
            self.imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing/2, bottom: 0, right: spacing/2)
            self.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing/2, bottom: 0, right: -spacing/2)
            
        case .imgageIsBottom:
            let imageTop = titleSize.height/2 + spacing/2
            let titleTop = -(imageSize.height/2 + spacing/2)
            if isTitleCompress {
                let imageLeft = (self.bounds.size.width - imageSize.width) / 2
                self.imageEdgeInsets = UIEdgeInsets(top: imageTop, left: imageLeft, bottom: -imageTop, right: 0)
                self.titleEdgeInsets = UIEdgeInsets(top: titleTop,
                                                    left: -imageSize.width, bottom: -titleTop, right: 0)
            } else {
                self.imageEdgeInsets = UIEdgeInsets(top: imageTop, left: titleSize.width/2, bottom: -imageTop, right: -titleSize.width/2)
                self.titleEdgeInsets = UIEdgeInsets(top: titleTop,
                                                    left: -imageSize.width/2, bottom: -titleTop, right: imageSize.width/2)
            }
            
        case .imageIsRight:
            self.imageEdgeInsets = UIEdgeInsets(top: 0, left: titleSize.width + spacing/2, bottom: 0,
                                                right: -(titleSize.width + spacing/2))
            self.titleEdgeInsets = UIEdgeInsets(top: 0, left: -(imageSize.width + spacing/2), bottom: 0, right: imageSize.width + spacing/2)
            
        case .normal:
            self.imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing/2, bottom: 0, right: spacing/2)
            self.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing/2, bottom: 0, right: -spacing/2)
        }
    }
}
