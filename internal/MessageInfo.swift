//
//  MessageInfo.swift
//  Pods
//
//  Created by muwa on 2025/10/9.
//

import Foundation


public class SWToolKit:NSObject {
 
    /// 是否打印数据
    public static var logInfo:Bool = false
    
}



class MessageInfo: NSObject {
    
    static func print(_ args: Any...) {
        #if DEBUG
        if SWToolKit.logInfo {
            Swift.print("==SWToolKit==",args)
        }
        #endif
    }
    
}
