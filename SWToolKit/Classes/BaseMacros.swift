//
//  BaseMacros.swift
//  SWToolKit
//
//  Created by shirley on 2022/2/25.
//

import Foundation
import UIKit
import AVFoundation


/// 当前活跃窗口场景（多窗口 / iPhone Duo 半屏时以活跃 scene 为准）
public func kActiveWindowScene() -> UIWindowScene? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    return scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
}

/// 底部安全区高度（动态读取，避免进程启动早期首次访问被定格为 0）
public var kSafeBtmH:CGFloat {
    kScreen.safeArea.bottom
}
/// 状态栏高度（动态读取；UIApplication.shared.windows 已弃用，改用 connectedScenes）
public var kStatusBarH:CGFloat {
    kActiveWindowScene()?.statusBarManager?.statusBarFrame.height ?? 0.0
}
/// 导航栏高度
public var kNaviH:CGFloat {
    kStatusBarH + 44.0
}
/// tabbar切换视图控制器高度
public var kTabBarH:CGFloat {
    kSafeBtmH + 49.0
}

public var kIphoneXUp:Bool { kSafeBtmH > 0 }

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
    public static var scale: CGFloat {
        kActiveWindowScene()?.screen.scale ?? UIScreen.main.scale
    }
    
    public static var width: CGFloat {
        kActiveWindowScene()?.coordinateSpace.bounds.width ?? UIScreen.main.bounds.size.width
    }
    
    public static var height: CGFloat {
        kActiveWindowScene()?.coordinateSpace.bounds.height ?? UIScreen.main.bounds.size.height
    }
    
    public static var maxL: CGFloat { max(width, height) }
    
    public static var minL: CGFloat { min(width, height) }
    /// 最大宽度（iPhone Duo 内屏/横屏不放大，半屏按比例缩）
    public static var maxWidth: CGFloat { kDevice.isPad ? 414 : min(minL, 466) }
    /// 最大高度
    public static var maxHeight: CGFloat { kDevice.isPad ? 896 : minL }
    /// UI水平方向对照比例
    public static var pt_x: CGFloat { maxWidth/375.0 }

    public static var safeArea:UIEdgeInsets {
        guard let scene = kActiveWindowScene() else { return .zero }
        guard let window = scene.keyWindow ?? scene.windows.first else { return .zero }
        return window.safeAreaInsets
    }
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


/// 内部设备信息（机型/电池/CPU 数据等对外能力由 SLExtensionKit 提供）
private enum SystemInfo {

    /// IP 地址
    static let ipAddress:String = {
        var addresses = [String]()
        var ifaddr : UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while (ptr != nil) {
                let flags = Int32(ptr!.pointee.ifa_flags)
                var addr = ptr!.pointee.ifa_addr.pointee
                if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                    if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                            if let address = String(validatingUTF8:hostname) {
                                addresses.append(address)
                            }
                        }
                    }
                }
                ptr = ptr!.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return addresses.first ?? "0.0.0.0"
    }()

    /// 硬件标识:(iPhone10,3)
    static let modeIdentifier:String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }()

    /// CPU 核心数
    static let cpuCores:Int = ProcessInfo.processInfo.activeProcessorCount
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
    /// 设置型号:(iPhone10,3)
    public static let modelIdentifier = SystemInfo.modeIdentifier
    /// 设备的别名::用户定义的名称
    public static let phoneName = UIDevice.current.name
    /// IP地址
    public static let ip = SystemInfo.ipAddress
    /// cpu
    public static let cpu = SystemInfo.cpuCores
    
}


public extension Notification.Name {
    /// window页面上将某个view放置到上层 或者 presentoViewController 时，发送这个通知
    static let windowBringSubview = NSNotification.Name("application_BringSubview")
    
}


/// window
public var kHighWindow:UIWindow? {
    get{
        if let window = kActiveWindowScene()?.keyWindow ?? kActiveWindowScene()?.windows.first {
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
        result = kHighWindow?.rootViewController
        
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
                for temWin in window.windowScene?.windows ?? [] {
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
