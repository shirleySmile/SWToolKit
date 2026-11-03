//
//  String+extend.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/1.
//
//  说明：纯 Foundation 的字符串能力已由 SLExtensionKit 提供，
//        本文件仅保留 UIKit / CoreGraphics 相关的部分。
//

import Foundation
import UIKit

extension String {

    /// 用浏览器打开网址
    public func openURL(){
        let open:String = self.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !open.isEmpty, let url = URL.init(string: open) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    /// 获取字符串的size
    public func size(width:Float, height:Float = MAXFLOAT, font:UIFont) -> CGSize{
        let rect = self.boundingRect(with: CGSize(width: CGFloat(width), height: CGFloat(height)), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font:font], context: nil)
        return rect.size
    }
}


extension CGFloat {

    /// 默认最多保留两位小数
    public func toString(_ min:Int = 0, _ max:Int = 2) -> String{
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = min
        formatter.maximumFractionDigits = max
        formatter.roundingMode = .halfUp
        return formatter.string(for: self) ?? ""
    }
}

extension CGRect {

    public func toString() -> String {
        return "{{ \(self.minX) , \(self.minY) } , { \(self.width) , \(self.height) }}"
    }
}
