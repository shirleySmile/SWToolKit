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
        if cString.count != 6 {
            return UIColor.clear
        }
        // 从六位数值中找到RGB对应的位数并转换
        let mask = 0x000000FF
        let r: Int
        let g: Int
        let b: Int
        
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        if #available(iOS 13.0, *) {
            // 系统版本高于13.0
            var color: UInt64 = 0
            let scanner = Scanner(string: cString)
            scanner.scanHexInt64(&color)
            
            
            r = Int(color >> 16) & mask
            g = Int(color >> 8) & mask
            b = Int(color) & mask
            
            red   = CGFloat(r)
            green = CGFloat(g)
            blue  = CGFloat(b)
            
        } else {
            // 系统版本低于13.0
            var color: UInt32 = 0
            let scanner = Scanner(string: cString)
            scanner.scanHexInt32(&color)
            
            r = Int(color >> 16) & mask
            g = Int(color >> 8) & mask
            b = Int(color) & mask
            
            red   = CGFloat(r)
            green = CGFloat(g)
            blue  = CGFloat(b)
            
        }
        return UIColor.init(red: (red / 255.0), green: (green / 255.0), blue: (blue / 255.0), alpha: a)
    }
    
    
}


extension UIColor {
    
    /// color转图片
    public func toImage(size:CGSize? = nil) -> UIImage {
        let rect = CGRect.init(x: 0, y: 0, width: size?.width ?? 1.0, height: size?.height ?? 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(self.cgColor)
        context?.fill(rect)
        let image:UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
}
