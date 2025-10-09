//
//  String+AttriString.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/3.
//

import Foundation
import UIKit
import CommonCrypto

extension String {
    
    /// 字符串前面或者后面加图片
   public func attachment(image:UIImage?, rect:CGRect, before:Bool = false) -> NSAttributedString {
        return attachment(image: image, rect: rect, before: before, font: nil, textColor: nil)
    }
    
    /// 字符串前面或者后面加图片，并且设置子图大小，字体颜色
   public func attachment(image:UIImage?, rect:CGRect, before:Bool, font:UIFont?, textColor:UIColor?) -> NSAttributedString {
        ///图片
       if let iconImg = image {
           let imgAtt = NSTextAttachment()
           imgAtt.image = iconImg
           imgAtt.bounds = rect
           let imgStr = NSAttributedString.init(attachment: imgAtt)
           
           ///文字
           let showStr = before == true ? " \(self)" : "\(self) "
           
           let muAttMuStr = NSMutableAttributedString.init(string: showStr)
           if let newFont = font {
               muAttMuStr.setAttributes([.font : newFont], range: NSMakeRange(0, showStr.count))
           }
           if let newColor = textColor {
               muAttMuStr.setAttributes([.foregroundColor : newColor], range: NSMakeRange(0, showStr.count))
           }
           
           ///拼接图片
           before ? muAttMuStr.insert(imgStr, at: 0) : muAttMuStr.append(imgStr)
           
           return muAttMuStr;
       }else{
           let attrStr = NSMutableAttributedString.init(string: self)
           if let newFont = font {
               attrStr.setAttributes([.font : newFont], range: NSMakeRange(0, self.count))
           }
           if let newColor = textColor {
               attrStr.setAttributes([.foregroundColor : newColor], range: NSMakeRange(0, self.count))
           }
           return attrStr
       }
    }
    
    ///string转换成html富文本
    public func toHtmlAttributedText(_ textColor:UIColor = .white) -> NSAttributedString? {
        guard let data = self.data(using: String.Encoding.utf8,
                                   allowLossyConversion: true) else { return nil }
        let options: [NSAttributedString.DocumentReadingOptionKey : Any] = [
            NSAttributedString.DocumentReadingOptionKey.characterEncoding : String.Encoding.utf8.rawValue,
            NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.html,
        ]
        let htmlString = try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil)
        htmlString?.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.clear, range: NSMakeRange(0, 1))
        return htmlString
        
    }
    
    
    ///自定义emoji文字
    public func changeTextForCustomEmoji(rect:CGRect, textFont:UIFont = .MSystemFont(15), textColor:UIColor = .black) -> NSAttributedString {
        
        let resultArr = machesEmoji()
        
        let attMuStr = NSMutableAttributedString.init(string: self)
        attMuStr.addAttributes([.foregroundColor:textColor,.font:textFont], range: .init(location: 0, length: attMuStr.length))
        
        if resultArr.count == 0 {return attMuStr}
        
        var lengthDetail = 0
        
        ///获取bundle
        let path = Bundle.main.path(forResource: "customEmoji", ofType: "bundle") ?? ""
        let bundle = Bundle.init(path: path)
        
        let replaceStr:NSString = NSString(string: self)
        
        for subResult in resultArr {
            //取出图片名
            let imageName = replaceStr.substring(with: subResult.range)
            var imgStr = NSAttributedString()
            var emojiImg = UIImage()
            emojiImg = UIImage.init(named: imageName, in: bundle, with: nil) ?? UIImage()
            
            let imgAtt = NSTextAttachment()
            imgAtt.image = emojiImg;
            imgAtt.bounds = rect;
            imgStr = NSAttributedString.init(attachment: imgAtt)
            
            //图片附件的文本长度是1
            let aLength = attMuStr.length;
            attMuStr.replaceCharacters(in: NSMakeRange(subResult.range.location - lengthDetail, subResult.range.length), with: imgStr)
            lengthDetail += aLength - attMuStr.length;
        }

        return attMuStr;
    }
    
    
    /// 设置文本下划线
    public func strikethroughStyle() -> NSAttributedString {
        let newAttr = NSMutableAttributedString.init(string: self)
//        newAttr.addAttribute(.strikethroughStyle, value:.underlineStyle , range: NSMakeRange(0, self.count))
        return newAttr
    }


    /// 设置文件间距
    public func lineSpace(_ space:Float) -> NSAttributedString {
        return textSpace(lineSpase: space, wordSpace: 0)
    }
    

    /// 字体间距
    public func textSpace(lineSpase:Float, wordSpace:Float) -> NSAttributedString {
        
        if self.count == 0 { return NSAttributedString.init(string: self) }
        
        if lineSpase <= 0 && wordSpace <= 0 { return NSAttributedString.init(string: self) }
        
        let attMuString = NSMutableAttributedString.init(string: self)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping
        if lineSpase > 0 {
            paragraphStyle.lineSpacing = CGFloat.init(lineSpase)
        }
        if wordSpace > 0 {
            paragraphStyle.paragraphSpacing = CGFloat.init(wordSpace)
        }
        attMuString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, self.count))

        return attMuString
    }

    
    
    /// 正则匹配emoji
    private func machesEmoji() -> [NSTextCheckingResult] {
        
        guard let expression = try? NSRegularExpression.init(pattern: "\\[\\w+\\]", options: .caseInsensitive) else {
            MessageInfo.print("正则表达式创建失败")
            return []
        }
        let machesString:NSString = NSString(string: self)
        return expression.matches(in: self, options: .reportProgress, range: NSMakeRange(0, machesString.length))
    }
    
     
}



 
