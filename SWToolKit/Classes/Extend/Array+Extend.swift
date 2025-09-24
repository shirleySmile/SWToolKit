//
//  Array+Extend.swift
//  SWToolKit
//
//  Created by shirley on 2022/8/17.
//

import Foundation

import UIKit

extension Array {
    
    public func toJson(options opt: JSONSerialization.WritingOptions = []) -> String {
        do {
            if (!JSONSerialization.isValidJSONObject(self)) {
                print("无法解析出JSONString")
                return ""
            }
            let data:NSData = try JSONSerialization.data(withJSONObject: self, options: opt) as NSData
            let JSONString = NSString(data:data as Data,encoding: String.Encoding.utf8.rawValue)
            return JSONString as? String ?? ""
        } catch {
            print("==SWToolKit==",error)
            return ""
        }
        
    }
    
    
    //打乱数组
    public static func shuffleArray(arr:[Int]) -> [Int] {
        var data:[Int] = arr
        for i in 1..<arr.count {
            let index:Int = Int(arc4random()) % i
            if index != i {
                data.swapAt(i, index)
            }
        }
        return data
    }
    
    
    /// 过滤不可转成json的数据
    public func filterError() -> [Dictionary<String, Any>]? {
        guard let tempArr = self as? [Dictionary<String, Any>], tempArr.count > 0 else { return nil }
        let newList:[Dictionary<String, Any>] = tempArr.compactMap { subDic in
            return subDic.filterError()
        }
        return newList
    }
    
    
    /// 是否需要过滤数据
    public func toString(options opt: JSONSerialization.WritingOptions = []) -> String? {
        if (!JSONSerialization.isValidJSONObject(self)) {
            print("无法解析出JSONString")
            return nil
        }
        guard let tempArr = self.filterError() else {
            print("过滤Array数据为空")
            return nil
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: tempArr, options: opt)
            let result = String(data: data , encoding: .utf8)
            return result
        } catch {
            print("==SWToolKit==",error)
            return nil
        }
    }
    
}

