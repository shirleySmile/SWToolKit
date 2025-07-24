//
//  DeviceInfo.swift
//  SWToolKit
//
//  Created by shirley on 2022/2/25.
//

import Foundation
import UIKit

public class DeviceInfo : NSObject {

    static let deviceModeIdentifier:String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }()
    
    ///ip地址
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

    
    
    public static func getOriginUUID() -> String {
        let puuid = CFUUIDCreate( nil );
        let uuidString = CFUUIDCreateString(nil, puuid);
        return (uuidString as String?)!
    }
    
    
    static func currentDeviceModelIdentifier() -> String{
        
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    
    static func currentDeviceModelName() -> String{
        let identifier = DeviceInfo.currentDeviceModelIdentifier()
        
        switch identifier {
        /// iPod
        case "iPod1,1":  return "iPod Touch 1"
        case "iPod2,1":  return "iPod Touch 2"
        case "iPod3,1":  return "iPod Touch 3"
        case "iPod4,1":  return "iPod Touch 4"
        case "iPod5,1":  return "iPod Touch 5"
        case "iPod7,1":  return "iPod Touch 6"
        case "iPod9,1":  return "iPod Touch 7"
            
            // iPhone
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":  return "iPhone 4"
        case "iPhone4,1":  return "iPhone 4s"
        case "iPhone5,1":  return "iPhone 5"
        case "iPhone5,2":  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":  return "iPhone 5s"
        case "iPhone7,2":  return "iPhone 6"
        case "iPhone7,1":  return "iPhone 6 Plus"
        case "iPhone8,1":  return "iPhone 6 s"
        case "iPhone8,2":  return "iPhone 6s Plus"
        case "iPhone8,4":  return "iPhone SE"
        case "iPhone9,1", "iPhone9,3":  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":  return "iPhone 7 Plus"
        case "iPhone10,1", "iPhone10,4": return "iPhone 8"
        case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        case "iPhone11,8":  return "iPhone XR"
        case "iPhone11,2":  return "iPhone XS"
        case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
        case "iPhone12,1":  return "iPhone 11"
        case "iPhone12,3":  return "iPhone 11 Pro"
        case "iPhone12,5":  return "iPhone 11 Pro Max"
        case "iPhone12,8":  return "iPhone SE (2ndGeneration)"
        case "iPhone13,1":  return "iPhone 12 mini"
        case "iPhone13,2":  return "iPhone 12"
        case "iPhone13,3":  return "iPhone 12 Pro"
        case "iPhone13,4":  return "iPhone 12 Pro Max"
        case "iPhone14,4":  return "iPhone 13 mini"
        case "iPhone14,5":  return "iPhone 13"
        case "iPhone14,2":  return "iPhone 13 Pro"
        case "iPhone14,3":  return "iPhone 13 Pro Max"
        case "iPhone14,6":  return "iPhone SE 2022"
        case "iPhone14,7":  return "iPhone 14"
        case "iPhone14,8":  return "iPhone 14 plus"
        case "iPhone15,2":  return "iPhone 14 Pro"
        case "iPhone15,3":  return "iPhone 14 Pro Max"
        case "iPhone15,4":  return "iPhone 15"
        case "iPhone15,5":  return "iPhone 15 Plus"
        case "iPhone16,1":  return "iPhone 15 Pro"
        case "iPhone16,2":  return "iPhone 15 Pro Max"


        /// iPad
        case "iPad1,1": return "iPad 1"
        case "iPad1,2": return "iPad 3G"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":  return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":  return "iPad 4"
        case "iPad6,11", "iPad6,12":  return "iPad 5"
        case "iPad7,5", "iPad7,6":  return "iPad 6"
        case "iPad7,11", "iPad7,12": return "iPad 7"
        case "iPad11,6", "iPad11,7": return "iPad 8"
        case "iPad12,1", "iPad12,2": return "iPad 9"
        case "iPad13,18", "iPad13,19": return "iPad10"
                
        /// iPad Air
        case "iPad4,1", "iPad4,2", "iPad4,3":  return "iPad Air"
        case "iPad5,3", "iPad5,4":  return "iPad Air 2"
        case "iPad11,3", "iPad11,4":  return "iPad Air 3"
        case "iPad13,1", "iPad13,2":  return "iPad Air 4"
        case "iPad13,16", "iPad13,17": return "iPad Air 5"


            
        /// iPad Pro
        case "iPad6,3", "iPad6,4":  return "iPad Pro (9.7-inch)"
        case "iPad6,7", "iPad6,8":  return "iPad Pro (12.9-inch)"
        case "iPad7,1", "iPad7,2":  return "iPad Pro (12.9-inch) 2nd"
        case "iPad7,3", "iPad7,4":  return "iPad Pro (10.5-inch)"
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":  return "iPad Pro (11-inch)"
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":  return "iPad Pro (12.9-inch) 3rd"
        case "iPad8,9", "iPad8,10":  return "iPadPro (11-inch) 2nd"
        case "iPad8,11", "iPad8,12":  return "iPadPro (12.9-inch) 4th"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7":  return "iPad Pro (11-inch) 3rd"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11":  return "iPad Pro (12.9-inch) 5th"

                
        /// iPad mini
        case "iPad2,5", "iPad2,6", "iPad2,7":  return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":  return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":  return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":  return "iPad Mini 4"
        case "iPad11,1", "iPad11,2":  return "iPad Mini 5"
        case "iPad14,1", "iPad14,2":  return "iPad Mini 6"


            
        ///appleTV
        case "AppleTV2,1":  return "Apple TV 2"
        case "AppleTV3,1","AppleTV3,2":  return "Apple TV 3"
        case "AppleTV5,3":  return "Apple TV 4"
            
        /// 模拟器
        case "i386", "x86_64":  return "Simulator"
            
        default:  return identifier
        }
        
    }


    
    //MARK: CPU频率------------------------------------------------
    static let CPUFrequency:Int = {
        let identifier = DeviceInfo.deviceModeIdentifier
        switch identifier {
            /// iPod
        case "iPod1,1":  return 400
        case "iPod2,1":  return 533
        case "iPod3,1":  return 600
        case "iPod4,1":  return 800
        case "iPod5,1":  return 1000
        case "iPod7,1":  return 1100
        case "iPod9,1":  return 2340
            
            // iPhone
        case "iPhone3,1", "iPhone3,2", "iPhone3,3", "iPhone4,1":  return 800
        case "iPhone5,1", "iPhone5,2":  return 1300
        case "iPhone5,3", "iPhone5,4":  return 1000
        case "iPhone6,1", "iPhone6,2":  return 1300
        case "iPhone7,1", "iPhone7,2":  return 1400
        case "iPhone8,1", "iPhone8,2", "iPhone8,4":  return 1850
        case "iPhone9,1", "iPhone9,2", "iPhone9,3", "iPhone9,4":  return 2340
        case "iPhone10,1", "iPhone10,2", "iPhone10,3", "iPhone10,4", "iPhone10,5", "iPhone10,6": return 2390
        case "iPhone11,2", "iPhone11,4", "iPhone11,6", "iPhone11,8": return 2490
        case "iPhone12,1", "iPhone12,3", "iPhone12,5", "iPhone12,8":  return 2650
        case "iPhone13,1", "iPhone13,2", "iPhone13,3", "iPhone13,4":  return 2990
        case "iPhone14,2", "iPhone14,3", "iPhone14,4", "iPhone14,5", "iPhone14,6", "iPhone14,7", "iPhone14,8":  return 3230
        case "iPhone15,2", "iPhone15,3", "iPhone15,4", "iPhone15,5":  return 3460
        case "iPhone16,1", "iPhone16,2":  return 3700
        case "iPhone17,3":  return 4040
        case "iPhone17,4":  return 4040 //"iPhone 16 Plus" 数据iphone16的数据猜测
        case "iPhone17,1":  return 4050
        case "iPhone17,2":  return 4050
            
            /// iPad
        case "iPad1,1", "iPad1,2": return 1000
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4","iPad2,5", "iPad2,6", "iPad2,7", "iPad3,1", "iPad3,2", "iPad3,3":  return 1000
        case "iPad3,4", "iPad3,5", "iPad3,6", "iPad4,1", "iPad4,2", "iPad4,3":  return 1400
        case "iPad4,4", "iPad4,5", "iPad4,6", "iPad4,7", "iPad4,8", "iPad4,9":  return 1300
        case "iPad5,1", "iPad5,2", "iPad5,3", "iPad5,4":  return 1500
        case "iPad6,3", "iPad6,4":  return 2160
        case "iPad6,7", "iPad6,8":  return 2240
        case "iPad6,11", "iPad6,12":  return 1850
        case "iPad7,1", "iPad7,2", "iPad7,3", "iPad7,4":  return 2380
        case "iPad7,5", "iPad7,6", "iPad7,11", "iPad7,12": return 2310
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4", "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8", "iPad8,9", "iPad8,10", "iPad8,11", "iPad8,12":  return 2490
        case "iPad11,6", "iPad11,7": return 2490
        case "iPad11,1", "iPad11,2", "iPad11,3", "iPad11,4":  return 2480
        case "iPad12,1", "iPad12,2":   return 2660
        case "iPad13,1", "iPad13,2":  return 2990
        case "iPad13,16", "iPad13,17": return 3200
        case "iPad14,1", "iPad14,2":   return 2930
        case "iPad13,18", "iPad13,19": return 3100
        case "iPad14,8", "iPad14,9":   return  3490   /// "iPad Air 11-inch (M2)"
        case "iPad14,10", "iPad14,11": return  3490   /// "iPad Air 13-inch (M2)"
        case "iPad16,3", "iPad16,4":   return 4510    /// "iPad Pro 11-inch (M4)"
        case "iPad16,5", "iPad16,6":   return 4510    /// "iPad Pro 13-inch (M4)"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7":  return 2490   ///"iPadPro(11-inch)3rd"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11":  return 3200    ///"iPadPro(12.9-inch)5th"
            
        default:  return 0
            
        }
        
    }()
    
    //MARK: 电池容量------------------------------------------------
    static let batteryCapacity:Int = {
        let identifier = DeviceInfo.deviceModeIdentifier
        switch identifier {
            /// iPod
        case "iPod1,1":  return 580
        case "iPod2,1":  return 730
        case "iPod3,1":  return 789
        case "iPod4,1":  return 930
        case "iPod5,1":  return 1030
        case "iPod7,1":  return 1043
        case "iPod9,1":  return 1043
            
            // iPhone
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":  return 1419
        case "iPhone4,1":  return 1432
        case "iPhone5,1", "iPhone5,2":  return 1434
        case "iPhone5,3", "iPhone5,4":  return 1508
        case "iPhone6,1", "iPhone6,2":  return 1508
        case "iPhone7,2":  return 1809
        case "iPhone7,1":  return 2906
        case "iPhone8,1":  return 1715
        case "iPhone8,2":  return 2750
        case "iPhone8,4":  return 1624
        case "iPhone9,1", "iPhone9,3":  return 1960
        case "iPhone9,2", "iPhone9,4":  return 2900
        case "iPhone10,1", "iPhone10,4": return 1821
        case "iPhone10,2", "iPhone10,5": return 2691
        case "iPhone10,3", "iPhone10,6": return 2716
        case "iPhone11,8":  return 2942
        case "iPhone11,2":  return 2658
        case "iPhone11,4", "iPhone11,6": return 3174
        case "iPhone12,1":  return 3110
        case "iPhone12,3":  return 3046
        case "iPhone12,5":  return 3969
        case "iPhone12,8":  return 1821
        case "iPhone13,1":  return 2227
        case "iPhone13,2":  return 2815
        case "iPhone13,3":  return 2815
        case "iPhone13,4":  return 3687
        case "iPhone14,4":  return 2406
        case "iPhone14,5":  return 3227
        case "iPhone14,2":  return 3095
        case "iPhone14,3":  return 4352
        case "iPhone14,6":  return 2200
        case "iPhone14,7":  return 3279
        case "iPhone14,8":  return 4325
        case "iPhone15,2":  return 3200
        case "iPhone15,3":  return 4323
        case "iPhone15,4":  return 3349
        case "iPhone15,5":  return 4383
        case "iPhone16,1":  return 3274
        case "iPhone16,2":  return 4422
        case "iPhone17,3":  return 3561
        case "iPhone17,4":  return 4006
        case "iPhone17,1":  return 3355
        case "iPhone17,2":  return 4676
            
            /// iPad
        case "iPad1,1", "iPad1,2": return 6600
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return 6930
        case "iPad2,5", "iPad2,6", "iPad2,7":  return 4440
        case "iPad3,1", "iPad3,2", "iPad3,3":  return 11560
        case "iPad3,4", "iPad3,5", "iPad3,6":  return 11560
        case "iPad4,1", "iPad4,2", "iPad4,3":  return 8820
        case "iPad4,4", "iPad4,5", "iPad4,6":  return 6471
        case "iPad4,7", "iPad4,8", "iPad4,9":  return 6471
        case "iPad5,1", "iPad5,2":  return 5124
        case "iPad5,3", "iPad5,4":  return 7340
        case "iPad6,3", "iPad6,4":  return 7306
        case "iPad6,7", "iPad6,8":  return 10307
        case "iPad6,11", "iPad6,12":  return 8820
        case "iPad7,1", "iPad7,2":  return 10875
        case "iPad7,3", "iPad7,4":  return 8134
        case "iPad7,5", "iPad7,6":  return 8820
        case "iPad7,11", "iPad7,12": return 8820
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":  return 7812
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":  return 9720
        case "iPad8,9", "iPad8,10":  return 7540
        case "iPad8,11", "iPad8,12":  return 9720
        case "iPad11,1", "iPad11,2":  return 5124
        case "iPad11,3", "iPad11,4":  return 8134
        case "iPad11,6", "iPad11,7": return 8757
        case "iPad12,1", "iPad12,2": return 8756
        case "iPad13,1", "iPad13,2":  return 7730
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7":  return 7743
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11":  return 11080
        case "iPad13,16", "iPad13,17":   return 7730
        case "iPad13,18", "iPad13,19": return 8800
        case "iPad14,1", "iPad14,2":  return 5257
        case "iPad16,3", "iPad16,4":   return 31290
        case "iPad16,5", "iPad16,6":   return 38990
        case "iPad14,8", "iPad14,9":   return 28930  /// "iPad Air 11-inch (M2)"
        case "iPad14,10", "iPad14,11": return 36590  /// "iPad Air 13-inch (M2)"
            
        default:  return 3227  /// 数据可能不全，防止崩溃 默认给一个数据:(iphone13的)
        }
    }()
    
    //MARK: 电池续航能力------------------------------------------------
    static let batteryUsageHours:Int = {
        let identifier = DeviceInfo.deviceModeIdentifier
        switch identifier {
            /// iPod
        case "iPod1,1":  return 48
        case "iPod2,1":  return 48
        case "iPod3,1":  return 48
        case "iPod4,1":  return 48
        case "iPod5,1":  return 48
        case "iPod7,1":  return 48
        case "iPod9,1":  return 48
            
            // iPhone
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":  return 18
        case "iPhone4,1":  return 18
        case "iPhone5,1", "iPhone5,2":  return 18
        case "iPhone5,3", "iPhone5,4":  return 18
        case "iPhone6,1", "iPhone6,2":  return 18
        case "iPhone7,2":  return 11
        case "iPhone7,1":  return 14
        case "iPhone8,1":  return 11
        case "iPhone8,2":  return 14
        case "iPhone8,4":  return 14
        case "iPhone9,1", "iPhone9,3":  return 14
        case "iPhone9,2", "iPhone9,4":  return 14
        case "iPhone10,1", "iPhone10,4": return 13
        case "iPhone10,2", "iPhone10,5": return 14
        case "iPhone10,3", "iPhone10,6": return 13
        case "iPhone11,8":  return 16
        case "iPhone11,2":  return 14
        case "iPhone11,4", "iPhone11,6": return 15
        case "iPhone12,1":  return 17
        case "iPhone12,3":  return 18
        case "iPhone12,5":  return 20
        case "iPhone12,8":  return 13
        case "iPhone13,1":  return 15
        case "iPhone13,2":  return 18
        case "iPhone13,3":  return 17
        case "iPhone13,4":  return 20
        case "iPhone14,4":  return 17
        case "iPhone14,5":  return 19
        case "iPhone14,2":  return 22
        case "iPhone14,3":  return 28
        case "iPhone14,6":  return 15
        case "iPhone14,7":  return 20
        case "iPhone14,8":  return 26
        case "iPhone15,2":  return 23
        case "iPhone15,3":  return 29
        case "iPhone15,4":  return 20
        case "iPhone15,5":  return 26
        case "iPhone16,1":  return 23
        case "iPhone16,2":  return 29
        case "iPhone17,3":  return 22
        case "iPhone17,4":  return 24
        case "iPhone17,1":  return 24
        case "iPhone17,2":  return 30
            
            
            /// iPad
        case "iPad1,1", "iPad1,2": return 10
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return 10
        case "iPad2,5", "iPad2,6", "iPad2,7":  return 10
        case "iPad3,1", "iPad3,2", "iPad3,3":  return 10
        case "iPad3,4", "iPad3,5", "iPad3,6":  return 10
        case "iPad4,1", "iPad4,2", "iPad4,3":  return 10
        case "iPad4,4", "iPad4,5", "iPad4,6":  return 10
        case "iPad4,7", "iPad4,8", "iPad4,9":  return 10
        case "iPad5,1", "iPad5,2":  return 10
        case "iPad5,3", "iPad5,4":  return 10
        case "iPad6,3", "iPad6,4":  return 10
        case "iPad6,7", "iPad6,8":  return 10
        case "iPad6,11", "iPad6,12":  return 10
        case "iPad7,1", "iPad7,2":  return 10
        case "iPad7,3", "iPad7,4":  return 10
        case "iPad7,5", "iPad7,6":  return 10
        case "iPad7,11", "iPad7,12": return 10
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":  return 10
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":  return 10
        case "iPad8,9", "iPad8,10":  return 10
        case "iPad8,11", "iPad8,12":  return 10
        case "iPad11,1", "iPad11,2":  return 10
        case "iPad11,3", "iPad11,4":  return 10
        case "iPad11,6", "iPad11,7": return 10
        case "iPad13,1", "iPad13,2":  return 10
        case "iPad12,1", "iPad12,2": return 10
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7":  return 10
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11":  return 10
        case "iPad13,16", "iPad13,17": return 10
        case "iPad13,18", "iPad13,19": return 10
        case "iPad14,1", "iPad14,2":  return 10
        case "iPad14,8", "iPad14,9":  return 10
        case "iPad14,10", "iPad14,11": return 10
        case "iPad16,3", "iPad16,4":   return 10
        case "iPad16,5", "iPad16,6":   return 10
            
        default:  return 10
            
        }
        
    }()
    
    //MARK: 手机型号------------------------------------------------
    static let deviceModeName:String = {
        let identifier = DeviceInfo.deviceModeIdentifier
        switch identifier {
            /// iPod
        case "iPod1,1":  return "iPod Touch 1"
        case "iPod2,1":  return "iPod Touch 2"
        case "iPod3,1":  return "iPod Touch 3"
        case "iPod4,1":  return "iPod Touch 4"
        case "iPod5,1":  return "iPod Touch 5"
        case "iPod7,1":  return "iPod Touch 6"
        case "iPod9,1":  return "iPod Touch 7"
            
            // iPhone
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":  return "iPhone 4"
        case "iPhone4,1":  return "iPhone 4s"
        case "iPhone5,1":  return "iPhone 5"
        case "iPhone5,2":  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":  return "iPhone 5s"
        case "iPhone7,2":  return "iPhone 6"
        case "iPhone7,1":  return "iPhone 6 Plus"
        case "iPhone8,1":  return "iPhone 6s"
        case "iPhone8,2":  return "iPhone 6s Plus"
        case "iPhone8,4":  return "iPhone SE"
        case "iPhone9,1", "iPhone9,3":  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":  return "iPhone 7 Plus"
        case "iPhone10,1", "iPhone10,4": return "iPhone 8"
        case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        case "iPhone11,8":  return "iPhone XR"
        case "iPhone11,2":  return "iPhone XS"
        case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
        case "iPhone12,1":  return "iPhone 11"
        case "iPhone12,3":  return "iPhone 11 Pro"
        case "iPhone12,5":  return "iPhone 11 Pro Max"
        case "iPhone12,8":  return "iPhone SE (2nd Generation)"
        case "iPhone13,1":  return "iPhone 12 mini"
        case "iPhone13,2":  return "iPhone 12"
        case "iPhone13,3":  return "iPhone 12 Pro"
        case "iPhone13,4":  return "iPhone 12 Pro Max"
        case "iPhone14,4":  return "iPhone 13 mini"
        case "iPhone14,5":  return "iPhone 13"
        case "iPhone14,2":  return "iPhone 13 Pro"
        case "iPhone14,3":  return "iPhone 13 Pro Max"
        case "iPhone14,6":  return "iPhone SE 2022"
        case "iPhone14,7":  return "iPhone 14"
        case "iPhone14,8":  return "iPhone 14 plus"
        case "iPhone15,2":  return "iPhone 14 Pro"
        case "iPhone15,3":  return "iPhone 14 Pro Max"
        case "iPhone15,4":  return "iPhone 15"
        case "iPhone15,5":  return "iPhone 15 Plus"
        case "iPhone16,1":  return "iPhone 15 Pro"
        case "iPhone16,2":  return "iPhone 15 Pro Max"
        case "iPhone17,3":  return "iPhone 16"
        case "iPhone17,4":  return "iPhone 16 Plus"
        case "iPhone17,1":  return "iPhone 16 Pro"
        case "iPhone17,2":  return "iPhone 16 Pro Max"
            
            /// iPad
        case "iPad1,1", "iPad1,2": return "iPad 1"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":  return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":  return "iPad 4"
        case "iPad6,11", "iPad6,12":  return "iPad 5"
        case "iPad7,5", "iPad7,6":  return "iPad 6"
        case "iPad7,11", "iPad7,12": return "iPad 7"
        case "iPad11,6", "iPad11,7": return "iPad 8"
        case "iPad12,1", "iPad12,2": return "iPad 9"
        case "iPad13,18", "iPad13,19": return "iPad 10"
            
            /// iPad Air
        case "iPad4,1", "iPad4,2", "iPad4,3":  return "iPad Air"
        case "iPad5,3", "iPad5,4":  return "iPad Air 2"
        case "iPad11,3", "iPad11,4":  return "iPad Air 3"
        case "iPad13,1", "iPad13,2":  return "iPad Air 4"
        case "iPad13,16", "iPad13,17": return "iPad Air 5"
        case "iPad14,8", "iPad14,9":   return "iPad Air M2 (11-inch)"
        case "iPad14,10", "iPad14,11":  return "iPad Air M2 (13-inch)"
            
            /// iPad Pro
        case "iPad6,3", "iPad6,4":  return "iPad Pro (9.7-inch)"
        case "iPad6,7", "iPad6,8":  return "iPad Pro (12.9-inch)"
        case "iPad7,1", "iPad7,2":  return "iPad Pro (12.9-inch) 2nd"
        case "iPad7,3", "iPad7,4":  return "iPad Pro (10.5-inch)"
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":  return "iPad Pro (11-inch)"
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":  return "iPad Pro (12.9-inch) 3rd"
        case "iPad8,9", "iPad8,10":  return "iPad Pro (11-inch) 2nd"
        case "iPad8,11", "iPad8,12":  return "iPad Pro (12.9-inch) 4th"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7":  return "iPad Pro (11-inch) 3rd"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11":  return "iPad Pro (12.9-inch) 5th"
        case "iPad16,3", "iPad16,4":  return "iPad Pro M4 (11-inch)"
        case "iPad16,5", "iPad16,6":  return "iPad Pro M4 (13-inch)"
            
            /// iPad mini
        case "iPad2,5", "iPad2,6", "iPad2,7":  return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":  return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":  return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":  return "iPad Mini 4"
        case "iPad11,1", "iPad11,2":  return "iPad Mini 5"
        case "iPad14,1", "iPad14,2":  return "iPad Mini 6"
            
            ///appleTV
        case "AppleTV2,1":  return "AppleTV2"
        case "AppleTV3,1","AppleTV3,2":  return "AppleTV3"
        case "AppleTV5,3":  return "AppleTV4"
            
            /// 模拟器
        case "i386", "x86_64" , "arm64":  return "Simulator"
            
        default:  return identifier
        }
    }()
    
}
