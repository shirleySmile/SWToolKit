//
//  UIFont+Extend.swift
//  SWToolKit
//
//  Created by shirley on 2022/7/25.
//

import Foundation
import UIKit
 

///< 适配，屏幕宽高适配比例，岭南以 iPhone6 模板设计
//let kAutoSizeScale_X = ((kScreenH == 667.0) ? 1.0 : (kMaxWidth / 375.0))
//let kAutoSizeScale_Y = ((kScreenH == 667.0) ? 1.0 : (kMaxHeight / 667.0))
 
let kAutoSizeScale_X = ((kScreen.height == 667.0) ? 1.0 : (kScreen.maxWidth / 375.0))
let kAutoSizeScale_Y = ((kScreen.height == 667.0) ? 1.0 : (kScreen.maxHeight / 667.0))

/**
 *floor 向下取整
 *ceil  向上取整
 ***/
///< 横向自适应拉伸
public func kAutoConvertWithScreenW_Value(_ value:CGFloat) -> CGFloat {
    return floor(value * kAutoSizeScale_X)
}
///< 纵向向自适应拉伸
func kAutoConvertWithScreenH_Value(_ value:CGFloat) -> CGFloat {
    return floor(value * kAutoSizeScale_Y)
}

extension UIFont {

    ///< 自适配 字体大小
    public static func MSystemFont(_ size:CGFloat) -> UIFont {
        return .init(name: "PingFangSC-Regular", size: kAutoConvertWithScreenW_Value(size)) ?? .systemFont(ofSize: kAutoConvertWithScreenW_Value(size))
//        return .systemFont(ofSize: kAutoConvertWithScreenW_Value(size))
    }
    
    ///< 自适配 加粗 字体大小
    public static func MBoldFont(_ size:CGFloat) -> UIFont {
        return .init(name: "PingFangSC-Blod", size: kAutoConvertWithScreenW_Value(size)) ?? .boldSystemFont(ofSize: kAutoConvertWithScreenW_Value(size))
//        return .boldSystemFont(ofSize: kAutoConvertWithScreenW_Value(size))
    }
    
    ///< 自适配 字体大小 字体重量
    public static func MSystemFont(_ size:CGFloat,_ weight:UIFont.Weight) -> UIFont {
        return .systemFont(ofSize: kAutoConvertWithScreenW_Value(size),weight:weight)
    }
    
    ///< 自适配 name 字体大小
    public static func MNameFont(_ name:String, _ size:CGFloat) -> UIFont {
        return UIFont(name: name, size: kAutoConvertWithScreenW_Value(size)) ?? UIFont.MSystemFont(size)
    }
    
     
}
 
 
