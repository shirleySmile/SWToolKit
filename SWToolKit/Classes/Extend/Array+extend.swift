//
//  Array+extend.swift
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
    
}
