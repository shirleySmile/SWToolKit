//
//  UILabel+extend.swift
//  SWToolKit
//
//  Created by shirley on 2022/8/9.
//

import Foundation
import UIKit
import CoreText


public extension UILabel{
    
    //判断文本标签的内容是否被截断
    func isTruncated (_ attrText : NSAttributedString,_ width:CGFloat, _ maxNumber:Int) -> Bool {
        let label = UILabel.init(frame: .init(x: 0, y: 0, width: width, height: 0))
        label.attributedText = attrText;
        label.font = self.font;
        label.numberOfLines = 0;
        label.sizeToFit()
        let height:CGFloat = label.frame.size.height
        //先用UILabel的 sizeToFit 计算出最佳大小，然后用高度/lineHeight就是行数，lineHeight为UIFont的属性
        let number:Int = Int(ceil(height)/label.font.lineHeight);
        return (number > maxNumber) ? true : false
    }
    
    
    //添加末尾
    func showTruncatedText(text: String ,textColor: UIColor?, labWidth:CGFloat, maxNum:Int = 5, atUsersRangs:[Dictionary<String,Any>]?){
        let lineArr:[Dictionary<String,Any>] = self.getLinesArrayOfString()
        if var att = self.attributedText, lineArr.count > maxNum{
            let dic = lineArr[maxNum-1]
            let lineRange = dic["range"] as! NSRange
            /// 一行的文字
            let lineStr = dic["str"] as! NSAttributedString
            let addTextW:CGFloat = ("..." + text).size(width: MAXFLOAT, font: self.font).width
            var subLength:Int = 0
            if lineStr.string.hasSuffix("\n") {
                subLength = 1
            }
            
            if lineStr.size().width > (labWidth - addTextW - 10) {

                /// 获取截取最少的字符串长度
                func rangeStringForMaxNumber(attrStr:NSAttributedString) -> Int {
                    var count = 0
                    for (_, str) in attrStr.string.enumerated().reversed() {
                        let oneStrRange = lineStr.string.nsRange(of: String(describing: str))
                        /// 剪切后的文字
                        let subAttrStr = lineStr.attributedSubstring(from: .init(location: 0, length: attrStr.length - oneStrRange.length))
                        if subAttrStr.size().width > (labWidth - addTextW - 10) {
                            return rangeStringForMaxNumber(attrStr: subAttrStr)
                        }else{
                            count = lineStr.length - subAttrStr.length
                            break
                        }
                    }
                    return count
                }
                
                subLength = rangeStringForMaxNumber(attrStr: lineStr)
                
                /// 判断At用户
                if let atUsers = atUsersRangs, atUsers.count > 0 {
                    let totalLength = lineRange.location + lineRange.length - subLength
                    for dicItem in atUsers {
                        let userRange = dicItem["range"] as! NSRange
                        if userRange.location<totalLength && (userRange.location+userRange.length)>totalLength {
                            subLength += (totalLength-userRange.location)
                            break
                        }
                    }
                }
                
            }
            
            att = att.attributedSubstring(from: .init(location: 0, length: lineRange.location + lineRange.length - subLength))
            
            let muAttr:NSMutableAttributedString = att.mutableCopy() as! NSMutableAttributedString
            muAttr.append(NSAttributedString(string: "..."))
            muAttr.append(NSAttributedString(string: text, attributes: [.foregroundColor:textColor ?? .black]))
            self.attributedText = muAttr
        }
    }
    
    
    /// 每一行的文字
    func getLinesArrayOfString() -> [Dictionary<String,Any>]{
        guard let attrText = self.attributedText else { return [] }
        let rect = self.frame
        let attStr = NSMutableAttributedString.init(attributedString: attrText)
        
        let cf_attStr = attStr as CFAttributedString
        let frameSetter = CTFramesetterCreateWithAttributedString(cf_attStr)
        
        
        let path = CGMutablePath()
        path.addRect(.init(x: 0, y: 0, width: rect.size.width, height: 1000000))
        
        let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)
        
        let lines = CTFrameGetLines(frame) as NSArray
        var linesArray:[Dictionary<String,Any>] = []
        for line in lines{
            let lineRef = line as! CTLine
            let lineRange = CTLineGetStringRange(lineRef)
            let range = NSRange.init(location: lineRange.location, length: lineRange.length)
            let lineString = attrText.attributedSubstring(from: range)
            linesArray.append(["range":range,"str":lineString])
        }
        return  linesArray
    }
    
    
}
