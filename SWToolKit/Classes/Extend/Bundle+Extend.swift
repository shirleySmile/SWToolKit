//
//  Bundle+Extend.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/12.
//

import Foundation

private class CBundleName: NSObject {}

/// 与Bundle相关的方法
extension Bundle {

    static func image(named:String) -> UIImage? {
        guard let path = Bundle(for: CBundleName.self).resourceURL ?? Bundle.main.resourceURL else {
            return nil
        }
        let mainBundle = Bundle.init(url: path)
        if let resourceBundlePath = mainBundle?.path(forResource: "SWToolKit", ofType: "bundle") {
            let imagePath = "SWToolKit.bundle/\(named)"
            let imgBundle = Bundle(path: resourceBundlePath)
            let img1 = UIImage(named: imagePath, in: imgBundle, compatibleWith: nil)
            return img1
        }
        return nil
    }
    
}


extension UIImage {
    
    static func bundle(imageNamed: String) -> UIImage {
        return Bundle.image(named: imageNamed) ?? UIImage()
    }

    private static func bundleImage(named imageName: String) -> UIImage {
        let imagePath = "SWToolKit.bundle/\(imageName)"
#if SWIFT_PACKAGE
        return UIImage(named: imagePath, in: .module, compatibleWith: nil) ?? UIImage()
#else
        let bundle = Bundle(for: CBundleName.self)
        return UIImage(named: imagePath, in: bundle, compatibleWith: nil) ?? UIImage()
#endif
    }
    
}
