//
//  Bundle+Extend.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/12.
//

import Foundation

/// 与Bundle相关的方法
public extension Bundle {
    
    ///查找项目中bundle路径  --- 动态库不能用或者libTool是动态库，导致这个不能用了
    convenience init?(name: String) {
        let bundlePath = Bundle.main.path(forResource: name, ofType: "bundle")
        if bundlePath != nil {
            self.init(path: bundlePath!)
        }else{
            self.init()
        }
    }
    
    
}
