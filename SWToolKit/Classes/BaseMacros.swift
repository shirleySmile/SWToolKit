//
//  BaseMacros.swift
//  SWToolKit
//
//  Created by shirley on 2022/2/25.
//

import Foundation
import UIKit
import AVFoundation


public let kSafeArea:UIEdgeInsets = {
    let scene = UIApplication.shared.connectedScenes.first
    guard let windowScene = scene as? UIWindowScene else { return .zero }
    guard let window = windowScene.windows.first else { return .zero }
    return window.safeAreaInsets
}()

/// 底部安全区高度
public let kSafeBtmH:CGFloat = kSafeArea.bottom
/// 状态栏高度
public let kStatusBarH = UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0
/// 导航栏高度
public let kNaviH = (kStatusBarH + 44.0)
/// tabbar切换视图控制器高度
public let kTabBarH = (kSafeBtmH + 49.0)
/// 分页
public let kPageSize = 20

public let kIphoneXUp:Bool = kSafeBtmH > 0 ? true : false

public let kIphone14ProUp:Bool = {
    let modeId = kDevice.modelIdentifier
    if modeId.contains("iPhone") {
        let firstStr = modeId.split(separator: ",").first
        if let num = Int(firstStr?.dropFirst(6) as? Substring ?? "0"){
            return (num >= 15 ? true : false)
        }else{
            return false
        }
    }else{
        return false
    }
}()

public struct kScreen {
    /// 屏幕分辨率
    public static let scale = UIScreen.main.scale
    
    public static let width = UIScreen.main.bounds.size.width
    
    public static let height = UIScreen.main.bounds.size.height
    
    public static let maxL = max(Self.width, Self.height)
    
    public static let minL = min(Self.width, Self.height)
    /// 最大宽度
    public static let maxWidth = (kDevice.isPad ? 414 : Self.minL)
    /// 最大高度
    public static let maxHeight = (kDevice.isPad ? 896 : Self.minL)
    /// UI水平方向对照比例
    public static let pt_x = Self.maxWidth/375.0

    
    public static let safeAreaInset:UIEdgeInsets = {
        if #available(iOS 13.0, *) {
            let scene = UIApplication.shared.connectedScenes.first
            guard let windowScene = scene as? UIWindowScene else { return .zero }
            guard let window = windowScene.windows.first else { return .zero }
            return window.safeAreaInsets
        } else if #available(iOS 11.0, *) {
            guard let window = UIApplication.shared.windows.first else { return .zero }
            return window.safeAreaInsets
        }
        return .zero
    }()
}



///App相关信息

public struct kApp {
    /// info.plist
    public static let infoDic = Bundle.main.infoDictionary!
    /// bundleID
    public static let bundleIdentifer = Bundle.main.bundleIdentifier!
    /// version版本号
    public static let shortVersion = Self.infoDic["CFBundleShortVersionString"] as! String
    /// build版本号
    public static let buildVersion = Self.infoDic[kCFBundleVersionKey as String] as! String
    /// app名称
    public static let name = Self.infoDic["CFBundleDisplayName"] as? String ?? ""
    
}


//用户设备信息
public struct kDevice {
    /// 机型
    public static let idiom:UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    /// 是否是IPhone
    public static let isPhone = (Self.idiom == .phone)
    /// 是否是isPad
    public static let isPad = (Self.idiom == .pad)
    /// 是否是isPad
    public static let isAppleTV = (Self.idiom == .tv)
    /// 设备的系统版本
    public static let systemVersion = UIDevice.current.systemVersion
    /// 获取设备具体型号:(iphone 6s plus)
    public static let modelName = DeviceInfo.currentDeviceModelName()
    /// 设置型号:(iPhone10,3)
    public static let modelIdentifier = DeviceInfo.currentDeviceModelIdentifier()
    /// 设备的别名::用户定义的名称
    public static let phoneName = UIDevice.current.name
    /// IP地址
    public static let ip = DeviceInfo.ipAddress
    
}


public extension Notification.Name {
    /// window页面上将某个view放置到上层 或者 presentoViewController 时，发送这个通知
    static let windowBringSubview = NSNotification.Name("application_BringSubview")
    
}


/// window
public var kHighWindow:UIWindow? {
    get{
        if let window = UIApplication.shared.connectedScenes.map({$0 as? UIWindowScene}).compactMap({$0}).first?.windows.first {
            return window
        }else{
            return UIApplication.shared.delegate?.window ?? nil
        }
    }
}


///当前的vc
public var kCurrentVC:UIViewController? {
    get{
        var result:UIViewController?
        let delegate  = UIApplication.shared.delegate
        result = delegate?.window??.rootViewController
        
        while (result?.presentedViewController != nil)  {
            result = result?.presentedViewController
        }
        
        if let tabbar = result as? UITabBarController , tabbar.selectedViewController != nil {
            result = tabbar.selectedViewController
        }
        
        while let navi = result as? UINavigationController , navi.topViewController != nil  {
            result = navi.topViewController
        }
        
        //以下是原来的
        if result == nil,  var window = kHighWindow {
            if window.windowLevel != .normal {
                for temWin in UIApplication.shared.windows {
                    if temWin.windowLevel == .normal {
                        window = temWin
                        break
                    }
                }
            }
            if window.subviews.count > 0 {
                let frontV = window.subviews.first
                let nextResponder = frontV?.next
                if nextResponder != nil && nextResponder!.isKind(of: UIViewController.self) {
                    result = nextResponder as? UIViewController
                }else{
                    result = window.rootViewController
                }
                
                if result != nil && result!.isKind(of: UITabBarController.self) {
                    result = (result as? UITabBarController)?.selectedViewController
                }
                if result != nil && result!.isKind(of: UINavigationController.self) {
                    result = (result as? UINavigationController)?.topViewController
                }
            }
        }
        return result
    }
}
