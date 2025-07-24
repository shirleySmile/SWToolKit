//
//  File.swift
//  SWToolKit
//
//  Created by shirley on 2022/11/8.
//

import Foundation

extension NSAttributedString{
    
    /// 字符串前面或者后面加图片
    public func appendAttachment(image:UIImage, rect:CGRect, before:Bool = false) -> NSAttributedString {
        ///图片
        let imgAtt = NSTextAttachment()
        imgAtt.image = image
        imgAtt.bounds = rect
        let imgStr = NSAttributedString.init(attachment: imgAtt)
        
        let muAtt = NSMutableAttributedString.init(attributedString: self)
        let spaceAtt = NSAttributedString.init(string: " ")
        if before {
            muAtt.insert(spaceAtt, at: 0)
            muAtt.insert(imgStr, at: 0)
        }else{
            muAtt.append(spaceAtt)
            muAtt.append(imgStr)
        }
        return muAtt
    }
    
    
    /// 设置文件间距
    @discardableResult
    public func lineSpace(_ space:Float) -> NSAttributedString {
        return textSpace(lineSpase: space, wordSpace: 0)
    }
    
    
    /// 字体间距
    @discardableResult
    public func textSpace(lineSpase:Float, wordSpace:Float) -> NSAttributedString {
        if self.length == 0 { return self }
        if lineSpase <= 0 && wordSpace <= 0 { return self }
        let attMuString:NSMutableAttributedString = self.mutableCopy() as! NSMutableAttributedString
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping
        if lineSpase > 0 {
            paragraphStyle.lineSpacing = CGFloat.init(lineSpase)
        }
        if wordSpace > 0 {
            paragraphStyle.paragraphSpacing = CGFloat.init(wordSpace)
        }
        attMuString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, self.length))
        
        return attMuString
    }
    
}
