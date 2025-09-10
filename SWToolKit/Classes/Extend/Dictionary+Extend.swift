//
//  Dictionary+extend.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/1.
//

import Foundation


extension Dictionary {
    
    

    /// 字典拼接字典
    mutating public func addDictionary(dic:Dictionary) {
        for (key,value) in dic {
            self[key] = value
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
            print("dictionary转换string错误:\(error)")
        }
        return result
    }
    
}

 
