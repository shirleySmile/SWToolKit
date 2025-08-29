//
//  DeviceModeType.swift
//  Pods
//
//  Created by muwa on 2025/8/29.
//

import Foundation


public enum DeviceModeType: String {
    
    case iPod_touch_1 = "iPod Touch 1"
    case iPod_touch_2 = "iPod Touch 2"
    case iPod_touch_3 = "iPod Touch 3"
    case iPod_touch_4 = "iPod Touch 4"
    case iPod_touch_5 = "iPod Touch 5"
    case iPod_touch_6 = "iPod Touch 6"
    case iPod_touch_7 = "iPod Touch 7"
    
    case iPhone_4 = "iPhone 4"
    case iPhone_4s = "iPhone 4s"
    case iPhone_5 = "iPhone 5"
    case iPhone_5c = "iPhone 5c"
    case iPhone_5s = "iPhone 5s"
    case iPhone_6 = "iPhone 6"
    case iPhone_6_plus = "iPhone 6 Plus"
    case iPhone_6s = "iPhone 6s"
    case iPhone_6s_plus = "iPhone 6s Plus"
    case iPhone_se = "iPhone SE"
    case iPhone_7 = "iPhone 7"
    case iPhone_7_plus = "iPhone 7 Plus"
    case iPhone_8 = "iPhone 8"
    case iPhone_8_plus = "iPhone 8 Plus"
    case iPhone_x = "iPhone X"
    case iPhone_xr = "iPhone XR"
    case iPhone_xs = "iPhone XS"
    case iPhone_xs_max = "iPhone XS Max"
    case iPhone_11 = "iPhone 11"
    case iPhone_11_pro = "iPhone 11 Pro"
    case iPhone_11_pro_max = "iPhone 11 Pro Max"
    case iPhone_se_2nd = "iPhone SE (2nd Generation)"
    case iPhone_12_mini = "iPhone 12 mini"
    case iPhone_12 = "iPhone 12"
    case iPhone_12_pro = "iPhone 12 Pro"
    case iPhone_12_pro_max = "iPhone 12 Pro Max"
    case iPhone_13_mini = "iPhone 13 mini"
    case iPhone_13 = "iPhone 13"
    case iPhone_13_pro = "iPhone 13 Pro"
    case iPhone_13_pro_max = "iPhone 13 Pro Max"
    case iPhone_se_2022 = "iPhone SE 2022"
    case iPhone_14 = "iPhone 14"
    case iPhone_14_plus = "iPhone 14 plus"
    case iPhone_14_pro = "iPhone 14 Pro"
    case iPhone_14_pro_max = "iPhone 14 Pro Max"
    case iPhone_15 = "iPhone 15"
    case iPhone_15_plus = "iPhone 15 Plus"
    case iPhone_15_pro = "iPhone 15 Pro"
    case iPhone_15_pro_max = "iPhone 15 Pro Max"
    case iPhone_16 = "iPhone 16"
    case iPhone_16_plus = "iPhone 16 Plus"
    case iPhone_16_pro = "iPhone 16 Pro"
    case iPhone_16_pro_max = "iPhone 16 Pro Max"
    case iPhone_16e = "iPhone 16e"
    
    /// iPad
    case iPad_1 = "iPad 1"
    case iPad_2 = "iPad 2"
    case iPad_3 = "iPad 3"
    case iPad_4 = "iPad 4"
    case iPad_5 = "iPad 5"
    case iPad_6 = "iPad 6"
    case iPad_7 = "iPad 7"
    case iPad_8 = "iPad 8"
    case iPad_9 = "iPad 9"
    case iPad_10 = "iPad 10"
    case iPad_16 = "iPad 16"

    /// iPad Air
    case iPad_air = "iPad Air"
    case iPad_air_2 = "iPad Air 2"
    case iPad_air_3 = "iPad Air 3"
    case iPad_air_4 = "iPad Air 4"
    case iPad_air_5 = "iPad Air 5"
    case iPad_air_m2_11 = "iPad Air M2 (11-inch)"
    case iPad_air_m2_13 = "iPad Air M2 (13-inch)"
    case iPad_air_m3_11 = "iPad Air M3 (11-inch)"
    case iPad_air_m3_13 = "iPad Air M3 (13-inch)"

    /// iPad Pro
    case iPad_pro_9_7 = "iPad Pro (9.7-inch)"
    case iPad_pro_12_9 = "iPad Pro (12.9-inch)"
    case iPad_pro_12_9_2nd = "iPad Pro (12.9-inch) 2nd"
    case iPad_pro_10_5 = "iPad Pro (10.5-inch)"
    case iPad_pro_11 = "iPad Pro (11-inch)"
    case iPad_pro_12_9_3rd = "iPad Pro (12.9-inch) 3rd"
    case iPad_pro_11_2nd = "iPad Pro (11-inch) 2nd"
    case iPad_pro_12_9_4th = "iPad Pro (12.9-inch) 4th"
    case iPad_pro_11_3rd = "iPad Pro (11-inch) 3rd"
    case iPad_pro_12_9_5th = "iPad Pro (12.9-inch) 5th"
    case iPad_pro_m4_11 = "iPad Pro M4 (11-inch)"
    case iPad_pro_m4_13 = "iPad Pro M4 (13-inch)"
    case iPad_pro_11_4th = "iPad Pro (11-inch) 4th"
    case iPad_pro_12_9_6th = "iPad Pro (12.9-inch) 6th"
     
    /// iPad mini
    case iPad_mini = "iPad Mini"
    case iPad_mini_2 = "iPad Mini 2"
    case iPad_mini_3 = "iPad Mini 3"
    case iPad_mini_4 = "iPad Mini 4"
    case iPad_mini_5 = "iPad Mini 5"
    case iPad_mini_6 = "iPad Mini 6"
    case iPad_mini_a17_pro = "iPad Mini (A17 Pro)"
    
    /// mac 型号
    
    
//    ///appleTV
//    case appleTV_2 = "AppleTV2"
//    case appleTV_3 = "AppleTV3"
//    case appleTV_4 = "AppleTV4"
     
    /// 模拟器
    case simulator = "Simulator"
        
}





extension DeviceModeType {
    
    static var nameType: DeviceModeType? {
        
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
            /// iPod
        case "iPod1,1":  return .iPod_touch_1
        case "iPod2,1":  return .iPod_touch_2
        case "iPod3,1":  return .iPod_touch_3
        case "iPod4,1":  return .iPod_touch_4
        case "iPod5,1":  return .iPod_touch_5
        case "iPod7,1":  return .iPod_touch_6
        case "iPod9,1":  return .iPod_touch_7
            
            // iPhone
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":  return .iPhone_4
        case "iPhone4,1":  return .iPhone_4s
        case "iPhone5,1", "iPhone5,2":  return .iPhone_5
        case "iPhone5,3", "iPhone5,4":  return .iPhone_5c
        case "iPhone6,1", "iPhone6,2":  return .iPhone_5s
        case "iPhone7,2":  return .iPhone_6
        case "iPhone7,1":  return .iPhone_6_plus
        case "iPhone8,1":  return .iPhone_6s
        case "iPhone8,2":  return .iPhone_6s_plus
        case "iPhone8,4":  return .iPhone_se
        case "iPhone9,1", "iPhone9,3":  return .iPhone_7
        case "iPhone9,2", "iPhone9,4":  return .iPhone_7_plus
        case "iPhone10,1", "iPhone10,4": return .iPhone_8
        case "iPhone10,2", "iPhone10,5": return .iPhone_8_plus
        case "iPhone10,3", "iPhone10,6": return .iPhone_x
        case "iPhone11,8":  return .iPhone_xr
        case "iPhone11,2":  return .iPhone_xs
        case "iPhone11,4", "iPhone11,6": return .iPhone_xs_max
        case "iPhone12,1":  return .iPhone_11
        case "iPhone12,3":  return .iPhone_11_pro
        case "iPhone12,5":  return .iPhone_11_pro_max
        case "iPhone12,8":  return .iPhone_se_2nd
        case "iPhone13,1":  return .iPhone_12_mini
        case "iPhone13,2":  return .iPhone_12
        case "iPhone13,3":  return .iPhone_12_pro
        case "iPhone13,4":  return .iPhone_12_pro_max
        case "iPhone14,4":  return .iPhone_13_mini
        case "iPhone14,5":  return .iPhone_13
        case "iPhone14,2":  return .iPhone_13_pro
        case "iPhone14,3":  return .iPhone_13_pro_max
        case "iPhone14,6":  return .iPhone_se_2022
        case "iPhone14,7":  return .iPhone_14
        case "iPhone14,8":  return .iPhone_14_plus
        case "iPhone15,2":  return .iPhone_14_pro
        case "iPhone15,3":  return .iPhone_14_pro_max
        case "iPhone15,4":  return .iPhone_15
        case "iPhone15,5":  return .iPhone_15_plus
        case "iPhone16,1":  return .iPhone_15_pro
        case "iPhone16,2":  return .iPhone_15_pro_max
        case "iPhone17,3":  return .iPhone_16
        case "iPhone17,4":  return .iPhone_16_plus
        case "iPhone17,1":  return .iPhone_16_pro
        case "iPhone17,2":  return .iPhone_16_pro_max
        case "iPhone17,5":  return .iPhone_16e

            /// iPad
        case "iPad1,1", "iPad1,2": return .iPad_1
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return .iPad_2
        case "iPad3,1", "iPad3,2", "iPad3,3":  return .iPad_3
        case "iPad3,4", "iPad3,5", "iPad3,6":  return .iPad_4
        case "iPad6,11", "iPad6,12":  return .iPad_5
        case "iPad7,5", "iPad7,6":  return .iPad_6
        case "iPad7,11", "iPad7,12": return .iPad_7
        case "iPad11,6", "iPad11,7": return .iPad_8
        case "iPad12,1", "iPad12,2": return .iPad_9
        case "iPad13,18", "iPad13,19": return .iPad_10
        case "iPad15,7", "iPad15,8":  return .iPad_16
            
            /// iPad Air
        case "iPad4,1", "iPad4,2", "iPad4,3":  return .iPad_air
        case "iPad5,3", "iPad5,4":  return .iPad_air_2
        case "iPad11,3", "iPad11,4":  return .iPad_air_3
        case "iPad13,1", "iPad13,2":  return .iPad_air_4
        case "iPad13,16", "iPad13,17": return .iPad_air_5
        case "iPad14,8", "iPad14,9":   return .iPad_air_m2_11
        case "iPad14,10", "iPad14,11":  return .iPad_air_m2_13
        case "iPad15,3", "iPad15,4":  return .iPad_air_m3_11
        case "iPad15,5", "iPad15,6":  return .iPad_air_m3_13

            /// iPad Pro
        case "iPad6,3", "iPad6,4":  return .iPad_pro_9_7
        case "iPad6,7", "iPad6,8":  return .iPad_pro_12_9
        case "iPad7,1", "iPad7,2":  return .iPad_pro_12_9_2nd
        case "iPad7,3", "iPad7,4":  return .iPad_pro_10_5
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":  return .iPad_pro_11
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":  return .iPad_pro_12_9_3rd
        case "iPad8,9", "iPad8,10":  return .iPad_pro_11_2nd
        case "iPad8,11", "iPad8,12":  return .iPad_pro_12_9_4th
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7":  return .iPad_pro_11_3rd
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11":  return .iPad_pro_12_9_5th
        case "iPad16,3", "iPad16,4":  return .iPad_pro_m4_11
        case "iPad16,5", "iPad16,6":  return .iPad_pro_m4_13
        case "iPad14,3", "iPad14,4":  return .iPad_pro_11_4th
        case "iPad14,5", "iPad14,6":  return .iPad_pro_12_9_6th
            
            
            /// iPad mini
        case "iPad2,5", "iPad2,6", "iPad2,7":  return .iPad_mini
        case "iPad4,4", "iPad4,5", "iPad4,6":  return .iPad_mini_2
        case "iPad4,7", "iPad4,8", "iPad4,9":  return .iPad_mini_3
        case "iPad5,1", "iPad5,2":  return .iPad_mini_4
        case "iPad11,1", "iPad11,2":  return .iPad_mini_5
        case "iPad14,1", "iPad14,2":  return .iPad_mini_6
        case "iPad16,1", "iPad16,2":  return .iPad_mini_a17_pro
            
        /**    ///appleTV
        case "AppleTV2,1":  return .appleTV_2
        case "AppleTV3,1","AppleTV3,2":  return .appleTV_3
        case "AppleTV5,3":  return .appleTV_4
         */
            
            /// 模拟器
        case "i386", "x86_64" , "arm64":  return .simulator
        default:  return nil
        }
    }
    
}



extension DeviceModeType {
    
    //MARK: 电池续航能力------------------------------------------------
    public func batteryUsageHours() -> Int {
        switch self {
        case .iPod_touch_1, .iPod_touch_2, .iPod_touch_3, .iPod_touch_4, .iPod_touch_5, .iPod_touch_6, .iPod_touch_7: return 48
        case .iPhone_4, .iPhone_4s, .iPhone_5, .iPhone_5c, .iPhone_5s: return 18
        case .iPhone_6, .iPhone_6s: return 11
        case .iPhone_6_plus, .iPhone_6s_plus, .iPhone_se: return 14
        case .iPhone_7, .iPhone_7_plus: return 14
        case .iPhone_8: return 13
        case .iPhone_8_plus: return 14
        case .iPhone_x: return 13
        case .iPhone_xr: return 16
        case .iPhone_xs: return 14
        case .iPhone_xs_max: return 15
        case .iPhone_11: return 17
        case .iPhone_11_pro: return 18
        case .iPhone_11_pro_max: return 20
        case .iPhone_se_2nd: return 13
        case .iPhone_12_mini: return 15
        case .iPhone_12: return 18
        case .iPhone_12_pro: return 17
        case .iPhone_12_pro_max: return 20
        case .iPhone_13_mini: return 17
        case .iPhone_13: return 19
        case .iPhone_13_pro: return 22
        case .iPhone_13_pro_max: return 28
        case .iPhone_se_2022: return 15
        case .iPhone_14: return 20
        case .iPhone_14_plus: return 26
        case .iPhone_14_pro: return 23
        case .iPhone_14_pro_max: return 29
        case .iPhone_15: return 20
        case .iPhone_15_plus: return 26
        case .iPhone_15_pro: return 23
        case .iPhone_15_pro_max: return 29
        case .iPhone_16: return 22
        case .iPhone_16_plus: return 24
        case .iPhone_16_pro: return 24
        case .iPhone_16_pro_max: return 30
        case .iPhone_16e: return 26
        case .iPad_1, .iPad_2, .iPad_3, .iPad_4, .iPad_5, .iPad_6, .iPad_7, .iPad_8, .iPad_9, .iPad_10, .iPad_16:
            return 10
        case .iPad_air, .iPad_air_2, .iPad_air_3, .iPad_air_4, .iPad_air_5, .iPad_air_m2_11, .iPad_air_m2_13, .iPad_air_m3_11, .iPad_air_m3_13:
            return 10
        case .iPad_pro_9_7, .iPad_pro_12_9, .iPad_pro_12_9_2nd, .iPad_pro_10_5, .iPad_pro_11, .iPad_pro_12_9_3rd, .iPad_pro_11_2nd:
            return 10
        case .iPad_pro_12_9_4th, .iPad_pro_11_3rd, .iPad_pro_12_9_5th, .iPad_pro_m4_11, .iPad_pro_m4_13, .iPad_pro_11_4th, .iPad_pro_12_9_6th:
            return 10
        case .iPad_mini, .iPad_mini_2, .iPad_mini_3, .iPad_mini_4, .iPad_mini_5, .iPad_mini_6, .iPad_mini_a17_pro:
            return 10
        case .simulator:
            return 10
        }
    }
    
    //MARK: 电池容量------------------------------------------------
    public func batteryCapacity() -> Int {
        switch self {
        case .iPod_touch_1:  return 580
        case .iPod_touch_2:  return 730
        case .iPod_touch_3:  return 789
        case .iPod_touch_4:  return 930
        case .iPod_touch_5:  return 1030
        case .iPod_touch_6, .iPod_touch_7:  return 1043
        case .iPhone_4:  return 1419
        case .iPhone_4s:  return 1432
        case .iPhone_5:  return 1434
        case .iPhone_5c:  return 1508
        case .iPhone_5s:  return 1508
        case .iPhone_6:  return 1809
        case .iPhone_6_plus:  return 2906
        case .iPhone_6s:  return 1715
        case .iPhone_6s_plus:  return 2750
        case .iPhone_se:  return 1624
        case .iPhone_7:  return 1960
        case .iPhone_7_plus:  return 2900
        case .iPhone_8:  return 1821
        case .iPhone_8_plus:  return 2691
        case .iPhone_x:  return 2716
        case .iPhone_xr:  return 2942
        case .iPhone_xs:  return 2658
        case .iPhone_xs_max:  return 3174
        case .iPhone_11:  return 3110
        case .iPhone_11_pro:  return 3046
        case .iPhone_11_pro_max:  return 3969
        case .iPhone_se_2nd:  return 1821
        case .iPhone_12_mini:  return 2227
        case .iPhone_12:  return 2815
        case .iPhone_12_pro:  return 2815
        case .iPhone_12_pro_max:  return 3687
        case .iPhone_13_mini:  return 2406
        case .iPhone_13:  return 3227
        case .iPhone_13_pro:  return 3095
        case .iPhone_13_pro_max:  return 4352
        case .iPhone_se_2022:  return 2200
        case .iPhone_14:  return 3279
        case .iPhone_14_plus:  return 4325
        case .iPhone_14_pro:  return 3200
        case .iPhone_14_pro_max:  return 4323
        case .iPhone_15:  return 3349
        case .iPhone_15_plus:  return 4383
        case .iPhone_15_pro:  return 3274
        case .iPhone_15_pro_max:  return 4422
        case .iPhone_16:  return 3561
        case .iPhone_16_plus:  return 4006
        case .iPhone_16_pro:  return 3355
        case .iPhone_16_pro_max:  return 4676
        case .iPhone_16e:  return 3961
        case .iPad_1:  return 6600
        case .iPad_2:  return 6930
        case .iPad_3:  return 11560
        case .iPad_4:  return 11560
        case .iPad_5:  return 8820
        case .iPad_6:  return 8820
        case .iPad_7:  return 8820
        case .iPad_8:  return 8757
        case .iPad_9:  return 8756
        case .iPad_10:  return 8800
        case .iPad_16: return 7600
        case .iPad_air: return 8820
        case .iPad_air_2: return 7340
        case .iPad_air_3: return 8134
        case .iPad_air_4: return 7730
        case .iPad_air_5: return 7730
        case .iPad_air_m2_11: return 7674
        case .iPad_air_m2_13: return 9705
        case .iPad_air_m3_11: return 7674
        case .iPad_air_m3_13: return 9705
        case .iPad_pro_9_7: return 7306
        case .iPad_pro_12_9: return 10307
        case .iPad_pro_12_9_2nd: return 10875
        case .iPad_pro_10_5: return 8134
        case .iPad_pro_11: return 7812
        case .iPad_pro_12_9_3rd: return 9720
        case .iPad_pro_11_2nd: return 7540
        case .iPad_pro_12_9_4th: return 9720
        case .iPad_pro_11_3rd: return 7743
        case .iPad_pro_12_9_5th: return 11080
        case .iPad_pro_m4_11: return 8160
        case .iPad_pro_m4_13: return 10538
        case .iPad_pro_11_4th: return 7538
        case .iPad_pro_12_9_6th: return 10915
        case .iPad_mini: return 4440
        case .iPad_mini_2: return 6471
        case .iPad_mini_3: return 6471
        case .iPad_mini_4: return 5124
        case .iPad_mini_5: return 5124
        case .iPad_mini_6: return 5257
        case .iPad_mini_a17_pro: return 5124
        case .simulator:
            return 3227  /// 数据可能不全，防止崩溃 默认给一个数据:(iphone13的)
        }
        
    }
    
    //MARK: cpu型号------------------------------------------------
    public func cpuMode() -> String {
        switch self {
        case .iPod_touch_1, .iPod_touch_2, .iPod_touch_3, .iPod_touch_4, .iPod_touch_5, .iPod_touch_6, .iPod_touch_7:
            return "A5-"
        case .iPhone_4, .iPhone_4s, .iPhone_5, .iPhone_5c, .iPhone_5s:
            return "A5-"
        case .iPhone_6, .iPhone_6_plus:
            return "A8"
        case .iPhone_6s, .iPhone_6s_plus, .iPhone_se:
            return "A9"
        case .iPhone_7, .iPhone_7_plus:
            return "A10 Fusion"
        case .iPhone_8, .iPhone_8_plus, .iPhone_x:
            return "A11 Bionic"
        case .iPhone_xr, .iPhone_xs, .iPhone_xs_max:
            return "A12 Bionic"
        case .iPhone_11, .iPhone_11_pro, .iPhone_11_pro_max, .iPhone_se_2nd:
            return "A13 Bionic"
        case .iPhone_12_mini, .iPhone_12, .iPhone_12_pro, .iPhone_12_pro_max:
            return "A14 Bionic"
        case .iPhone_13_mini, .iPhone_13, .iPhone_13_pro, .iPhone_13_pro_max, .iPhone_se_2022:
            return "A15 Bionic"
        case .iPhone_14, .iPhone_14_plus:
            return "A15 Bionic"
        case .iPhone_14_pro, .iPhone_14_pro_max, .iPhone_15, .iPhone_15_plus:
            return "A16 Bionic"
        case .iPhone_15_pro, .iPhone_15_pro_max:
            return "A17 Bionic"
        case .iPhone_16, .iPhone_16_plus, .iPhone_16e:
            return "A18"
        case .iPhone_16_pro, .iPhone_16_pro_max:
            return "A18 Pro"
        case .iPad_1, .iPad_2, .iPad_3, .iPad_4, .iPad_5, .iPad_6, .iPad_7, .iPad_8:
            return "A5X-"
        case .iPad_9:
            return "A13 Bionic"
        case .iPad_10:
            return "A14 Bionic"
        case .iPad_16:
            return "A15 Bionic"
        case .iPad_air:
            return "A5X-"
        case .iPad_air_2, .iPad_air_3, .iPad_air_4:
            return "A8X"
        case .iPad_air_5:
            return "M1"
        case .iPad_air_m2_11, .iPad_air_m2_13:
            return "M2"
        case .iPad_air_m3_11, .iPad_air_m3_13:
            return "M3"
        case .iPad_pro_9_7:
            return "A9X"
        case .iPad_pro_12_9:
            return "A12X Bionic"
        case .iPad_pro_12_9_2nd:
            return "A12X Bionic"
        case .iPad_pro_10_5:
            return "A10X"
        case .iPad_pro_11, .iPad_pro_11_3rd, .iPad_pro_11_2nd:
            return "A12X Bionic"
        case .iPad_pro_12_9_3rd, .iPad_pro_12_9_4th, .iPad_pro_12_9_5th:
            return "A12X Bionic"
        case .iPad_pro_m4_11, .iPad_pro_m4_13:
            return "M4"
        case .iPad_pro_11_4th, .iPad_pro_12_9_6th:
            return "M2"
        case .iPad_mini:
            return "A5"
        case .iPad_mini_2, .iPad_mini_3:
            return "A7"
        case .iPad_mini_4:
            return "A8"
        case .iPad_mini_5:
            return "A12"
        case .iPad_mini_6:
            return "A15 Bionic"
        case .iPad_mini_a17_pro:
            return "A17 Pro"
        case .simulator:
            return "Simulator"
        }
    }
    
    //MARK: cpu频率------------------------------------------------
    public func cpuFrequency() -> Int {
        switch self {
        case .iPod_touch_1: return 400
        case .iPod_touch_2: return 533
        case .iPod_touch_3: return 600
        case .iPod_touch_4: return 800
        case .iPod_touch_5: return 1000
        case .iPod_touch_6: return 1100
        case .iPod_touch_7: return 2340
        case .iPhone_4, .iPhone_4s: return 800
        case .iPhone_5, .iPhone_5s: return 1300
        case .iPhone_5c: return 1000
        case .iPhone_6, .iPhone_6_plus: return 1400
        case .iPhone_6s, .iPhone_6s_plus, .iPhone_se: return 1850
        case .iPhone_7, .iPhone_7_plus: return 2340
        case .iPhone_8, .iPhone_8_plus, .iPhone_x: return 2390
        case .iPhone_xr, .iPhone_xs, .iPhone_xs_max: return 2490
        case .iPhone_11, .iPhone_11_pro, .iPhone_11_pro_max, .iPhone_se_2nd: return 2650
        case .iPhone_12_mini, .iPhone_12, .iPhone_12_pro, .iPhone_12_pro_max: return 2990
        case .iPhone_13_mini, .iPhone_13, .iPhone_13_pro, .iPhone_13_pro_max, .iPhone_se_2022: return 3230
        case .iPhone_14, .iPhone_14_plus: return 3230
        case .iPhone_14_pro, .iPhone_14_pro_max, .iPhone_15, .iPhone_15_plus: return 3460
        case .iPhone_15_pro, .iPhone_15_pro_max: return 3700
        case .iPhone_16, .iPhone_16_plus: return 4040
        case .iPhone_16_pro, .iPhone_16_pro_max: return 4050
        case .iPhone_16e: return 4050
        case .iPad_1, .iPad_2, .iPad_3: return 1000
        case .iPad_4: return 1400
        case .iPad_5: return 1850
        case .iPad_6: return 2310
        case .iPad_7: return 2310
        case .iPad_8: return 2490
        case .iPad_9: return 2660
        case .iPad_10: return 3100
        case .iPad_16: return 3500
        case .iPad_air: return 1400
        case .iPad_air_2: return 1500
        case .iPad_air_3: return 2480
        case .iPad_air_4: return 2990
        case .iPad_air_5: return 3200
        case .iPad_air_m2_11, .iPad_air_m2_13: return 3490
        case .iPad_air_m3_11, .iPad_air_m3_13: return 4050
        case .iPad_pro_9_7: return 2160
        case .iPad_pro_12_9: return 2240
        case .iPad_pro_12_9_2nd, .iPad_pro_10_5: return 2380
        case .iPad_pro_11, .iPad_pro_12_9_3rd, .iPad_pro_11_2nd, .iPad_pro_12_9_4th, .iPad_pro_11_3rd: return 2490
        case .iPad_pro_12_9_5th: return 3200
        case .iPad_pro_m4_11, .iPad_pro_m4_13: return 4510
        case .iPad_pro_11_4th, .iPad_pro_12_9_6th: return 3490
        case .iPad_mini: return 1000
        case .iPad_mini_2, .iPad_mini_3: return 1300
        case .iPad_mini_4: return 1500
        case .iPad_mini_5: return 2480
        case .iPad_mini_6: return 2930
        case .iPad_mini_a17_pro: return 3780
        case .simulator: return 1000
        }
    }
    
}








