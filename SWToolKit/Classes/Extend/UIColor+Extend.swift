//
//  Color+Extend.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/3.
//

import Foundation
import UIKit

fileprivate struct rgbValue{
    var red, green, blue : CGFloat
}


/// 与UIColor相关的方法
extension UIColor{
    
    public convenience init(r:Float, g:Float, b:Float, a:CGFloat = 1.0) {
        self.init(red: CGFloat(r / 255.0), green: CGFloat(g / 255.0), blue: CGFloat(b / 255.0), alpha: a)
    }
    
    /// int类型的颜色值
    public convenience init(_ rgbValue: UInt, alpha:Float = 1.0){
        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0, green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0, blue:  CGFloat(rgbValue & 0x0000FF) / 255.0, alpha: CGFloat(alpha))
    }
    
    
    // UIColor -> Hex String
    public var hexString: String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        let multiplier = CGFloat(255.999999)
        
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        
        if alpha == 1.0 {
            return String(
                format: "#%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier)
            )
        }
        else
        {
            return String(
                format: "#%02lX%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier),
                Int(alpha * multiplier)
            )
        }
    }
    
    /// 十六进制字符串转换UIColor
    /// - Parameters:
    ///   - hex: 十六进制字符串
    ///   - a: 透明度(默认透明度为1)
    /// - Returns: UIColor
    
    public static func color(hex: String, a:CGFloat = 1.0) -> UIColor {
        var cString : String = hex.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        // String should be 6 or 8 characters
        if cString.count < 6 {
            return UIColor.clear
        }
        // 判断前缀
        if cString.hasPrefix("0x") {
            cString.removeFirst(2)
        }
        if cString.hasPrefix("0X") {
            cString.removeFirst(2)
        }
        if cString.hasPrefix("#") {
            cString.removeFirst(1)
        }
        // 6 位（RRGGBB）或 8 位（RRGGBBAA），超出范围视为非法
        if cString.count != 6 && cString.count != 8 {
            return UIColor.clear
        }
        // 从十六进制数值中找到 RGBA 对应的位数并转换
        let mask = 0x000000FF

        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        var alpha: CGFloat = a
        var color: UInt64 = 0
        let scanner = Scanner(string: cString)
        scanner.scanHexInt64(&color)

        if cString.count == 8 {
            // 8 位：RRGGBBAA，需按 4 字节拆分
            red   = CGFloat(Int(color >> 24) & mask)
            green = CGFloat(Int(color >> 16) & mask)
            blue  = CGFloat(Int(color >> 8)  & mask)
            alpha = CGFloat(Int(color)       & mask) / 255.0
        } else {
            // 6 位：RRGGBB，alpha 用调用方传入的 a
            red   = CGFloat(Int(color >> 16) & mask)
            green = CGFloat(Int(color >> 8)  & mask)
            blue  = CGFloat(Int(color)       & mask)
            alpha = a
        }
        return UIColor.init(red: (red / 255.0), green: (green / 255.0), blue: (blue / 255.0), alpha: alpha)
    }
    
    
}


extension UIColor {
    
    /// color转图片
    public func toImage(size:CGSize? = nil) -> UIImage {
        let rect = CGRect.init(x: 0, y: 0, width: size?.width ?? 1.0, height: size?.height ?? 1.0)
        /// UIGraphicsBeginImageContext 自 iOS 15 起弃用且只输出 1x 图，改用 UIGraphicsImageRenderer（自动匹配屏幕 scale）
        return UIGraphicsImageRenderer(size: rect.size).image { context in
            context.cgContext.setFillColor(self.cgColor)
            context.cgContext.fill(rect)
        }
    }
    
}
