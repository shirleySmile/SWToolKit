//
//  Dictionary+extend.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/1.
//

import Foundation


extension Dictionary {
    
    
    /// 字典拼接字典
    mutating public func merge(other dic:Dictionary) {
        self.merge(dic) { curr, new in
            new
        }
    }

    
    /// 字典转字符串
    public func toJson(options opt: JSONSerialization.WritingOptions = []) -> String {
        if self.count == 0 {
            return ""
        }
        var result:String = ""
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: opt)
            result = String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
        } catch {
            debugPrint("==SWToolKit==" + "dictionary转换string错误:\(error)")
        }
        return result
    }
    
    
    /// 检测json的value值是否为非基础数据类型
    public func filterError() -> [String:Any]? {
        guard let tempDic = self as? [String:Any], tempDic.count > 0 else {
            return nil
        }
        var newDic:[String:Any] = tempDic
        tempDic.forEach { key, value in
            if let dict = value as? [String: Any] {
                let tempDic = dict.filterError()
                newDic[key] = tempDic
            } else if let arr = value as? [Dictionary<String, Any>] {
                var list:[Dictionary<String,Any>] = Array()
                for (_, dict) in arr.enumerated() {
                    if let tempDic = dict.filterError() {
                        list.append(tempDic)
                    }
                }
                newDic[key] = list
            } else if let new = value as? NSError {
                var errDic:[String: Any] = ["domain": new.domain, "code": "\(new.code)", "localizedDescription": new.localizedDescription]
                if let userInfo = new.userInfo.filterError() {
                    errDic["userInfo"] = userInfo
                }
                let tempDic = errDic.filterError()
                newDic[key] = tempDic
            } else if let new = value as? String {
                newDic[key] = new
            } else {
                newDic[key] = "\(value)"
            }
        }
        return newDic
    }
    
    
    /// 字典转字符串
    public func toString(options opt: JSONSerialization.WritingOptions = []) -> String? {
        if self.count == 0 {
            return nil
        }
        guard let json = self.filterError() else {
            debugPrint("==SWToolKit==" + "不是基本的数据类型")
            return nil
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: opt)
            let result = String(data: jsonData, encoding: String.Encoding.utf8)
            return result
        } catch {
            debugPrint("==SWToolKit==" + "dictionary转换string错误:\(error)")
            return nil
        }
        
    }
    
}


 
