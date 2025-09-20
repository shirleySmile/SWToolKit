//
//  NaviView+Extend.swift
//  SWToolKit
//
//  Created by shirley on 2022/4/14.
//

import Foundation
import UIKit

public class CNavItemBaseView: UIControl {
    
    enum ViewPosition {
        case right
        case left
        case center
        case other
    }
    
    ///确定在哪一便的位置
    var navPosition:ViewPosition = .other
    fileprivate static let baseHeight:CGFloat = 40.0
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var bounds = self.bounds
        bounds = bounds.insetBy(dx: -0.5*10, dy: -0.5*10)
        return bounds.contains(point)
    }
    
}


//MARK: 每个item
public class CNaviItemView: CNavItemBaseView {

    /// 独立方法是为了可以不修改返回的按钮图片，只添加点击事件
    /// - Parameter image: 返回按钮的图片
    public static func navBackView(_ image: UIImage? = CNaviBar.barInfo.backImage, tintColor:UIColor? = nil) -> CNaviItemView {
        return showImage(image, tintColor: tintColor)
    }

    /// 本地图片
    /// - Parameters:
    ///   - image: 图片
    ///   - width: 按钮宽度(固定宽度，若没有，取图片宽度+间距)
    ///   - space: 图片左右内边距
    public static func showImage(_ image:UIImage?, width:CGFloat? = nil, space:CGFloat = 0, tintColor:UIColor? = nil) -> CNaviItemView {
        let item = CNaviItemView.getBaseItem()
        if let image {
            let imgV = UIImageView.init()
            if let tintC = tintColor {
                imgV.image = image.withRenderingMode(.alwaysTemplate)
                imgV.tintColor = tintC
            }else{
                imgV.image = image
            }
            let viewW:CGFloat = (width ?? (image.size.width+space*2.0))
            imgV.tag = 9999
            imgV.contentMode = .scaleAspectFit
            item.addSubview(imgV)
            imgV.snp.makeConstraints { make in
                make.center.equalTo(item)
                make.size.equalTo(CGSize.init(width: viewW - space*2.0, height: item.height))
            }
            item.width = viewW
        }
        return item
    }
    

    /// 显示的文字
    /// - Parameters:
    ///   - text: 文字
    ///   - with: 默认宽度
    ///   - height: 高度
    ///   - fontSize: 字体大小
    ///   - color: 文字颜色
    ///   - inset: 内边距
    /// - Returns:
    public static func showText(_ text:String?, font fSize:UIFont? = .MSystemFont(15), textColor color:UIColor?, inset:UIEdgeInsets? = nil) -> CNaviItemView {
        let item = CNaviItemView.getBaseItem()
        if text != nil {
            let lab = UILabel.init()
            lab.text = text
            lab.textColor = color
            lab.tag = 999
            lab.font = fSize
            lab.textAlignment = .center
            item.addSubview(lab)
            lab.snp.makeConstraints { make in
                make.center.equalTo(item)
            }
            lab.layoutIfNeeded()
            /// 计算文字尺寸
            let size = text?.size(width: MAXFLOAT, height: Float(self.baseHeight), font: fSize ?? .MSystemFont(15))
            var insetW:CGFloat = 0
            var insetH:CGFloat = 0
            if let inset = inset {
                insetW = inset.left + inset.right
                insetH = inset.top + inset.bottom
            }
            item.width = max((size?.width ?? self.baseHeight) + insetW, self.baseHeight)
            item.height = min((size?.height ?? self.baseHeight) + insetH, self.baseHeight)
        }
        return item
    }
    
    

    ///修改图片
    public func itemImage(image:UIImage?){
        let imageV:UIImageView = self.viewWithTag(9999) as! UIImageView
        imageV.tag = 9999
        imageV.image = image
    }
    ///修改字体颜色
    public func itemTitle(title:String?){
        let label:UILabel = self.viewWithTag(999) as! UILabel
        label.text = title
    }
    ///修改字体颜色
    public func itemTextColor(color:UIColor? = .black){
        let label:UILabel = self.viewWithTag(999) as! UILabel
        label.textColor = color
    }
    ///基础Btn
    fileprivate static func getBaseItem(_ with:CGFloat = 40,_ height:CGFloat = 40) -> CNaviItemView {
        let item = CNaviItemView.init(frame: CGRect(x: 0, y: 0, width: with, height: height))
        return item
    }
    
}


extension UIView {
    
    public func convertToCNaviItemView() -> CNaviItemView{
        if self.isKind(of: CNaviItemView.self) {
            return self as! CNaviItemView
        }
        let cnavItemV = CNaviItemView.getBaseItem(0, 0)
        cnavItemV.addSubview(self)
        if self.width > 0 && self.height > 0 {
            self.origin = .zero
            cnavItemV.size = .init(width: self.width, height: self.height)
        }else{
            self.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        return cnavItemV
    }
    
}




