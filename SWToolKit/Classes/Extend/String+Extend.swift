//
//  String+extend.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/1.
//

import Foundation
import CommonCrypto
import UIKit
import CryptoKit


extension String {
    
    ///字符串变Dictionary
    public func toDictionary() -> [String : Any]? {
        guard !self.isEmpty else { return nil }
        guard let dataSelf = self.data(using: .utf8) else { return nil }
        
        if let dic = try? JSONSerialization.jsonObject(with: dataSelf,
                                                       options: .mutableContainers) as? [String : Any] {
            return dic
        }
        return nil
    }
    
    /// 字符串转Array
    public func toArray() -> [Any]? {
        guard !self.isEmpty else { return nil }
        guard let dataSelf = self.data(using: .utf8) else { return nil }
        if let arr = try? JSONSerialization.jsonObject(with: dataSelf,
                                                       options: .mutableContainers) as? [Any] {
            return arr
        }
        return nil
        
    }
    
    
    /// String使用下标截取字符串
    /// string[index] 例如："abcdefg"[3] // c
    subscript (i:Int)->String {
        let startIndex = self.index(self.startIndex, offsetBy: i)
        let endIndex = self.index(startIndex, offsetBy: 1)
        return String(self[startIndex..<endIndex])
    }
    
    /// String使用下标截取字符串
    /// string[index..<index] 例如："abcdefg"[3..<4] // d
    subscript (r: Range<Int>) -> String {
        get {
            if r.lowerBound <= self.count && r.upperBound <= self.count {
                let startIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
                let endIndex = self.index(self.startIndex, offsetBy: r.upperBound)
                return String(self[startIndex..<endIndex])
            }else{
                return self
            }
        }
    }
    
    /// String使用下标截取字符串
    /// string[index,length] 例如："abcdefg"[3,2] // de
    subscript (index:Int , length:Int) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: index)
            let endIndex = self.index(startIndex, offsetBy: length)
            return String(self[startIndex..<endIndex])
        }
    }
    
    
    /// 字符串截取
    public func substring(location:Int, length:Int) -> String {
        if length <= 0 { return self }
        if self.count < (location + length) { return self }
        return self[location..<(location+length)]
    }
    
    
    /// 系统md5方法
    public var md5:String {
        let digest = Insecure.MD5.hash(data: self.data(using: .utf8) ?? Data())
        return digest.map {
            String(format: "%02hhx", $0)
        }.joined()
    }
    
    
    /// 隐藏rang内的数据替换
    public mutating func hidden(r: ClosedRange<Int>, with:String) -> String {
        if self.count > 0 && r.isEmpty == false && self.count > r.upperBound {
            let start = r.lowerBound
            let end = r.upperBound
            let range = self.index(self.startIndex, offsetBy: start)...self.index(self.startIndex, offsetBy:end)
            self.replaceSubrange(range, with: with)
        }
        return self
    }
    
    /// 验证是否可为密码
    public func validPassword() -> Bool{
        let rages = "^(?![0-9]+$)(?![a-zA-Z]+$)[0-9A-Za-z]{6,50}$"
        let pred = NSPredicate(format: "SELF MATCHES %@", rages)
        return pred.evaluate(with: self) ? true : false
    }
    
    
    /// base64 编码
    public func base64Encoded() -> String{
        let utf8str = self.data(using: .utf8)
        let base64Encoded  = utf8str?.base64EncodedString()
        return base64Encoded ?? ""
    }
    
    /// 获取子字符串的范围NSRange
    public func nsRange(of subString: String) -> NSRange {
        let text = NSString.init(string: self)
        return text.range(of: subString)
    }
    
    /// 去掉空格
    public func trimmingWhitespace() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    /// 用浏览器打开网址
    public func openURL(){
        let open:String = self.trimmingWhitespace()
        if open.count > 0 && UIApplication.shared.canOpenURL(URL.init(string: open)!) {
            UIApplication.shared.open(URL.init(string: open)!)
        }
    }
    
    /// 获取字符串的size
    public func size(width:Float, height:Float = MAXFLOAT, font:UIFont) -> CGSize{
        let rect = self.boundingRect(with: CGSize(width: CGFloat(width), height: CGFloat(height)), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font:font], context: nil)
        return rect.size
    }
    ///判断是否是手机号
    public func isPhoneNumber() -> Bool{
        //        let  MOBILE = "^1(3[0-9]|4[579]|5[0-35-9]|6[6]|7[0-35-9]|8[0-9]|9[89])\\d{8}$"
        let  MOBILE = "^(13[0-9]|14[01456879]|15[0-35-9]|16[2567]|17[0-8]|18[0-9]|19[0-35-9])\\d{8}$"
        let regextestmobile = NSPredicate.init(format: "SELF MATCHES %@", MOBILE)
        
        return regextestmobile.evaluate(with: self)
    }
    
    ///判断是否是手机号2(废弃)
    public func isMobile() -> Bool{
        /**
         * 手机号码
         * 移动：134/135/136/137/138/139/150/151/152/157/158/159/182/183/184/187/188/147/178
         * 联通：130/131/132/155/156/185/186/145/176
         * 电信：133/153/180/181/189/177
         */
        
        let MOBILE = "^1(3[0-9]|5[0-35-9]|8[025-9])\\d{8}$"
        /**
         * 中国移动：China Mobile
         * 134[0-8]/135/136/137/138/139/150/151/152/157/158/159/182/183/184/187/188/147/178
         */
        let CM = "^1(34[0-8]|(3[5-9]|5[0127-9]|8[23478]|47|78)\\d)\\d{7}$"
        /**
         * 中国联通：China Unicom
         * 130/131/132/152/155/156/185/186/145/176
         */
        let CU = "^1(3[0-2]|5[256]|8[56]|45|76)\\d{8}$"
        /**
         * 中国电信：China Telecom
         * 133/153/180/181/189/177
         */
        let CT = "^1((33|53|77|8[019])[0-9]|349)\\d{7}$";
        
        let regextestmobile = NSPredicate(format: "SELF MATCHES %@",MOBILE)
        
        let regextestcm = NSPredicate(format: "SELF MATCHES %@",CM)
        
        let regextestcu = NSPredicate(format: "SELF MATCHES %@",CU)
        
        let regextestct = NSPredicate(format: "SELF MATCHES %@",CT)
        
        if  regextestmobile.evaluate(with: self) == true ||
                regextestcm.evaluate(with: self) == true ||
                regextestcu.evaluate(with: self) == true ||
                regextestct.evaluate(with: self) == true {
            return true
        }else{
            return false
        }
    }
    
    //是否包含中文
    public func isContainChinese() -> Bool {
        for (_, value) in self.enumerated() {
            if ("\u{4E00}" <= value  && value <= "\u{9FA5}") {
                return true
            }
        }
        
        return false
    }
    
    //转换url中的中文
    public func urlEncoding() -> String{
        if self.isEmpty == true {
            return self
        }
        //包含中文
        if !self.isContainChinese(){
            return self
        }
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    }
    

    //安全的base64编码
    public func safeBase64Encode() -> String{
        if self.isEmpty == true{
            return self
        }
        
        var text = self.data(using: .utf8)?.base64EncodedString(options:.endLineWithLineFeed)
        text = text?.replacingOccurrences(of: "+", with: "-")
        text = text?.replacingOccurrences(of: "/", with: "_")
        text = text?.replacingOccurrences(of: "=", with: "")
        
        return text ?? ""
    }
    
    public func isIDNumber() -> Bool{
        //判断位数
        if self.count != 15 && self.count != 18 {
            return false
        }
        
        var carid = self
        
        var lSumQT = 0
        
        //加权因子
        let R = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
        
        //校验码
        let sChecker: [Int8] = [49,48,88, 57, 56, 55, 54, 53, 52, 51, 50]
        
        //将15位身份证号转换成18位
        let mString = NSMutableString.init(string: self)
        
        if self.count == 15 {
            mString.insert("19", at: 6)
            var p = 0
            let pid = mString.utf8String
            for i in 0...16 {
                let t = Int(pid![i])
                p += (t - 48) * R[i]
            }
            let o = p % 11
            let stringContent = NSString(format: "%c", sChecker[o])
            mString.insert(stringContent as String, at: mString.length)
            carid = mString as String
        }
        
        let cStartIndex = carid.startIndex
        let _ = carid.endIndex

        //判断年月日是否有效
        //年份
        let yStartIndex = carid.index(cStartIndex, offsetBy: 6)
        let yEndIndex = carid.index(yStartIndex, offsetBy: 4)
        let strYear = Int(carid[yStartIndex..<yEndIndex])
        
        //月份
        let mStartIndex = carid.index(yEndIndex, offsetBy: 0)
        let mEndIndex = carid.index(mStartIndex, offsetBy: 2)
        let strMonth = Int(carid[mStartIndex..<mEndIndex])
        
        //日
        let dStartIndex = carid.index(mEndIndex, offsetBy: 0)
        let dEndIndex = carid.index(dStartIndex, offsetBy: 2)
        let strDay = Int(carid[dStartIndex..<dEndIndex])
        
        let localZone = NSTimeZone.local
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.timeZone = localZone
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let date = dateFormatter.date(from: "\(String(format: "%02d",strYear!))-\(String(format: "%02d",strMonth!))-\(String(format: "%02d",strDay!)) 12:01:01")
        
        if date == nil {
            return false
        }
        let paperId = carid.utf8CString
        //检验长度
        if 18 != carid.count {
            return false
        }
        //校验数字
        func isDigit(c: Int) -> Bool {
            return 0 <= c && c <= 9
        }
        for i in 0...18 {
            let id = Int(paperId[i])
            if isDigit(c: id) && !(88 == id || 120 == id) && 17 == i {
                return false
            }
        }
        //验证最末的校验码
        for i in 0...16 {
            let v = Int(paperId[i])
            lSumQT += (v - 48) * R[i]
        }
        if sChecker[lSumQT%11] != paperId[17] {
            return false
        }
        return true
    }
    
    ///是否是微信号
    public func isWechatNumber() -> Bool{
        let regexStr = "^[a-zA-Z][a-zA-Z0-9_-]{5,19}$"
        let regex = NSPredicate.init(format: "SELF MATCHES %@", regexStr)
        let isResult = regex.evaluate(with: self)
        return isResult
    }
    
    /// 随机字符串， 默认十位数
    public static func random(num:Int = 10) -> String{
        let uuid:String = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        guard num < uuid.count else {
            return uuid
        }
        let maxStartIndex = uuid.count - num
        let randomStartIndex = Int.random(in: 0...maxStartIndex)
        let random:String = uuid.substring(location: randomStartIndex, length: num)
        return random
    }
}


// MARK: 字符串转成数字
extension String {
    
    public func intValue() -> Int {
        return Int.init(self) ?? 0
    }
    public func doubleValue() -> Double {
        return Double.init(self) ?? 0
    }
    public func floatValue() -> Float {
        return Float.init(self) ?? 0
    }
    public func boolValue() -> Bool{
        return self.intValue() > 0 ? true : false
    }
}

//MARK: - 表情
extension Character {
    
    //简单的emoji是一个标量 以emoji的形式呈现给用户
    var isSimpleEmoji: Bool {
        guard let firstProperties = unicodeScalars.first?.properties else {
            return false
        }
        return unicodeScalars.count == 1 && (firstProperties.isEmojiPresentation || firstProperties.generalCategory == .otherSymbol)
    }
    
    //检测标量是否将合并到emoji中
    var isCombineIntoEmoji: Bool{
        return unicodeScalars.count > 1 && unicodeScalars.contains{$0.properties.isJoinControl || $0.properties.isVariationSelector}
    }
    
    //属否为emoji表情
    public var isEmoji: Bool {
        return isSimpleEmoji || isCombineIntoEmoji
    }
}

extension String {
    
    //是否为单个emoji表情
    var isSingleEmoji: Bool {
        return count == 1 && containsEmoji
    }
    
    //是否包含emoji表情
    var containsEmoji: Bool {
        return contains{$0.isEmoji}
    }
    
    //只包含emoji表情
    var containsOnlyEmoji: Bool {
        return !isEmpty && !contains{!$0.isEmoji}
    }
    
    //提取emoji表情字符串
    public var emojiString: String {
        return emojis.map{ String($0) }.reduce("",+)
    }
    
    //获取emoji表情数组
    public var emojis: [Character] {
        return filter{$0.isEmoji}
    }
    
    //提取单元编码标量
    public var emojiScallars: [UnicodeScalar] {
        return filter{$0.isEmoji}.flatMap{ $0.unicodeScalars}
    }
    
    //将unicode字符串转成表情
    public func emojDecode() -> String {
        let data = self.data(using: .utf8)!
        return String(data: data, encoding: .nonLossyASCII) ?? self
    }
    //将表情字符转成unicode字符串
    public func emojEncode() -> String {
        let data = self.data(using: .nonLossyASCII, allowLossyConversion: true)!
        return String(data: data, encoding: .utf8)!
    }
    
}


// MARK: 转换成字符串
extension Int64 {
    public func toString() -> String{
        return String.init(self)
    }
}

extension Int32 {
    public func toString() -> String{
        return String.init(self)
    }
}

extension Int {
    public func toString() -> String{
        return String.init(self)
    }

    
    /// 获取从from到to的随机整数数组（包括from 不包括to,from和to均 >= 0）
    /// - Parameters:
    ///   - arr: 初始空数组
    ///   - totalNum: 获取总数
    ///   - from: 最小整数 >= 0
    ///   - to: 最大整数 >= 0
    ///   - callBack: 返回
    public static func getRandNumArray(arr:[Int] = [],totalNum:Int = 1,from:Int = 0,to:Int = 0,callBack:((_ nums:Array<Int>)-> Void)){
        let num = Int.random(in:from..<to)
        var array = arr
        var haveNum = false
        for currentNum in array where currentNum == num{
            haveNum = true
            break
        }
        if haveNum {
            self.getRandNumArray(arr: array,totalNum: totalNum,from: from,to: to,callBack: callBack)
        }else{
            array.append(num)
            if array.count == totalNum{
                callBack(array)
            }else{
                self.getRandNumArray(arr: array,totalNum: totalNum,from: from,to: to,callBack: callBack)
            }
        }
        
    }
}

extension Double {
    /// 默认最多保留两位小数
    public func toString(_ min:Int = 0, _ max:Int = 2) -> String{
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = min
        formatter.maximumFractionDigits = max
        formatter.roundingMode = .halfUp
        return formatter.string(for: self) ?? ""
    }
}

extension Float {
    /// 默认最多保留两位小数
    public func toString(_ min:Int = 0, _ max:Int = 2) -> String{
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = min
        formatter.maximumFractionDigits = max
        formatter.roundingMode = .halfUp
        return formatter.string(for: self) ?? ""
    }
}

extension Decimal {
    /// 默认最多保留两位小数
    public func toString(_ min:Int = 0, _ max:Int = 2) -> String{
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = min
        formatter.maximumFractionDigits = max
        formatter.roundingMode = .halfUp
        return formatter.string(for: self) ?? ""
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



extension Substring {
    func toString() -> String {
        return String(self)
    }
}
