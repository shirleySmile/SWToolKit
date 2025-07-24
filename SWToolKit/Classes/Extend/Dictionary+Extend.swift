//
//  Dictionary+extend.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/1.
//

import Foundation


extension Dictionary {
    
    /// 字典转字符串
    public func converToJsonData() -> String{
        
        if self.count == 0 {
            return ""
        }
          
        var jsonStr:String = ""
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted])
            jsonStr = String.init(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            print("dictionary转换string错误:\(error)")
        }
        
        jsonStr = jsonStr.replacingOccurrences(of: "\n", with: "")
        return jsonStr
    }
    
    /// 字典拼接字典
    mutating public func addDictionary(dic:Dictionary) {
        for (key,value) in dic {
            self[key] = value
        }
    }

    
    public func toJson() -> String {
        var result:String = ""
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted])
            if let JSONString = String(data: jsonData, encoding: String.Encoding.utf8) {
                result = JSONString
            }
        } catch {
            result = ""
        }
        return result
    }
    
}

 
