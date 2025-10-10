//
//  MessageInfo.swift
//  Pods
//
//  Created by muwa on 2025/10/9.
//

import Foundation



class MessageInfo: NSObject {
    
    static func print(_ args: Any...) {
        #if DEBUG
        if SWToolKit.logInfo {
            Swift.print("==SWToolKit==",args)
        }
        #endif
    }
    
}
