//
//  Bundle+Extend.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/12.
//

import Foundation

private class CBundleName: NSObject {}

/// 与Bundle相关的方法
public extension Bundle {

    static func image(named: String) -> UIImage? {
        // 注意：CocoaPods 生成的 SWToolKit.bundle 里还嵌套了一层 SWToolKit.bundle
        // （podspec 直接打包了 Assets 下现成的 bundle），所以这里要带上前缀。
        guard let resourceBundleURL = Bundle(for: CBundleName.self).url(forResource: "SWToolKit", withExtension: "bundle"),
              let resourceBundle = Bundle(url: resourceBundleURL) else {
            return nil
        }
        // 调用方传的名字有的带 .png 后缀、有的不带，这里统一补全。
        let fileName = named.hasSuffix(".png") ? named : "\(named).png"
        guard let imagePath = resourceBundle.path(forResource: "SWToolKit.bundle/\(fileName)", ofType: nil) else {
            return nil
        }
        // 用 contentsOfFile 而不是 UIImage(named:in:)，避免 UIKit 去没有 Assets.car 的
        // resource bundle 里找 asset catalog，从而打印 CoreUI 的 "unable to find bundle" 警告。
        return UIImage(contentsOfFile: imagePath)
    }
    
}


public extension UIImage {
    
    static func bundle(imageNamed: String) -> UIImage? {
        return Bundle.image(named: imageNamed)
    }
    
}
