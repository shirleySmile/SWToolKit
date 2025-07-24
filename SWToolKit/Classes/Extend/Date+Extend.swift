//
//  DateExtend.swift
//  SWToolKit
//
//  Created by shirley on 2022/2/22.
//

import Foundation


extension Date {
    
//    public func stringFmt(fmt: String) -> String{
//        let dataFmt = DateFormatter()
//        dataFmt.locale = Locale.init(identifier: "zh_CN")
//        dataFmt.dateFormat = fmt;
//        return dataFmt.string(from: self)
//    }
//    
//    public static func dateFormatter(fmt : String, time: String) -> Date{
//        let dataFmt = DateFormatter()
//        dataFmt.locale = Locale.init(identifier: "zh_CN")
//        dataFmt.dateFormat = fmt
//        let date = dataFmt.date(from: time)
//        return date ?? Date.init()
//    }
//    
    
    
    ///普遍时间格式
//    static public func getTimeDifference(time: Date) -> String {
//         let calendar = Calendar.current
//         let fromComp = calendar.dateComponents(in: .current, from: time)
//         let toComp = calendar.dateComponents(in: .current, from: Date())
//
//
//         var showTime = "" ///具体显示时间
//         let timeStr = time.stringFmt( "HH:mm")  /// 时分
//         let days:[Substring] = time.stringFmt( "yyyy-MM-dd").split(separator: "-")///年月日
//        ///是否为今天
//        if calendar.isDateInToday(time) {
//            showTime = timeStr
//        } else if calendar.isDateInYesterday(time) {
//            showTime = "txt_date_select_yesterday".local
//        }else {
//            if fromComp.year == toComp.year {
//                showTime = days[1] + "txt_date_select_month".local + days[2] + "txt_date_select_day".local
//
//            }else{
//                showTime = days[1] + "txt_date_select_month".local + days[2] + "txt_date_select_day".local
//
//            }
//        }
//         return showTime
//    }
     
    
    /// 获取指定时间前或者后的时间（年月日）
    /// - Parameters:
    ///   - date: 指定时间
    ///   - year: 年间隔
    ///   - month: 月间隔
    ///   - day: 日间隔
    /// - Returns: 返回相应的时间
    public func getLaterDateFromDate(year:Int,month:Int,day:Int) -> Date{
        let calendar:Calendar = Calendar(identifier: .gregorian)
        let adcomps = NSDateComponents()
        adcomps.year = year
        adcomps.month = month
        adcomps.day = day
        let newdate = calendar.date(byAdding: adcomps as DateComponents, to: self, wrappingComponents: false)
        return newdate!
    }
    
    
    /// 计算两个日期相差多少天
    /// - Parameters:
    ///   - startDate: 开始
    ///   - endDate: 结束
    /// - Returns: 返回天数
    public static func getDiffDay(startDate:Date? = Date(),endDate:Date? = Date()) -> Int{
          let formatter = DateFormatter()
          let calendar = Calendar.current
          formatter.dateFormat = "yyyy-MM-dd"
          let diff:DateComponents = calendar.dateComponents([.day], from: startDate!, to: endDate!)
          return diff.day!
    }
    
    
    /// 获取指定时间的年
    /// - Parameter date: 指定时间
    /// - Returns: 返回年数字
    public func getYear() -> Int?{
        let calendar = NSCalendar.current
        let com = calendar.dateComponents([.year,.month,.day], from:self)
        return com.year
    }
    
    
    /// 获取指定时间的月
    /// - Parameter date: 指定时间
    /// - Returns: 返回月数字
    public func getMonth() -> Int?{
        let calendar = NSCalendar.current
        let com = calendar.dateComponents([.year,.month,.day], from:self)
        return com.month
    }
    
    /// 获取指定时间的日
    /// - Parameter date: 指定时间
    /// - Returns: 返回日数字
    public func getDay() -> Int?{
        let calendar = NSCalendar.current
        let com = calendar.dateComponents([.year,.month,.day], from:self)
        return com.day
    }
    
    
    /// 某个日期和设定日期比较大小
    /// - Parameters:
    ///   - date: 比较的时间
    ///   - formatter: 时间格式
    /// - Returns: 1:某个日期比设定日期大， -1:某个日期比设定日期小。 0:相同
//    public func compare(date:Date, formatter:String = "yyyy-MM-dd") -> Int{
//
//        let newSelfDate:Date = Date.dateFormatter(fmt: formatter, time: self.stringFmt( formatter) )
//        let newCompareDate:Date = Date.dateFormatter(fmt: formatter, time: date.stringFmt( formatter) )
//
//        let result = newSelfDate.compare(newCompareDate)
//        switch result {
//        case .orderedAscending:
//            return -1
//        case .orderedDescending:
//            return 1
//        case .orderedSame:
//            return 0
//        }
//    }
    
    /// 比较两个时间大小
    /// - Parameters:
    ///   - startDate: 开始时间
    ///   - endDate: 结束时间
    /// - Returns: 结果
    public static func compare(startDate:Date?, endDate:Date?) -> Int{
        let intervalStart = startDate!.timeIntervalSince1970
        let intervalStop = endDate!.timeIntervalSince1970
        // -1:开始时间大于结束时间    0:开始时间等于结束时间    1:开始时间小于结束时间
        return (intervalStart >  intervalStop) ? -1 : (intervalStart <  intervalStop ? 1 : 0)
    }
    
  
    /// 获取某年某月有多少天
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份
    /// - Returns: 返回天数目
    public static func getDaysWith(year:Int,month:Int) -> Int{
        switch month {
        case 1,3,5,7,8,10,12:
            return 31
        case 4,6,9,11:
            return 30
        case 2:
            return ((year%4 == 0 && year%100 != 0) || (0 == year%400)) ? 29 : 28
        default:
            return 30
        }

    }
    //时间戳字符串转date
    public static func timeStampStringToDate(timeStamp:Double, dateFormat:String="yyyy-MM-dd HH:mm:ss") -> Date {
        let timeZone = TimeZone.init(identifier: "UTC") //这是重点
        let dateFormatter = DateFormatter.init()
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = dateFormat
        let time = timeStamp/1000
        let date = Date(timeIntervalSince1970:time)
        return date
    }
    
    //时间戳转格式
    public static func getTimeFromtimeStamp(timeStamp: Double,format:String = "yyyy-MM-dd HH:mm:ss")->String {
        //时间戳为毫秒级要 ／ 1000， 秒就不用除1000，参数带没带000
        let timeSta:TimeInterval = TimeInterval(timeStamp / 1000)
        let date = NSDate(timeIntervalSince1970: timeSta)
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = format
        return dateformatter.string(from: date as Date)
    }
    
    /// 获取当前 秒级 时间戳 - 10位
    public var timeStamp : String {
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let timeStamp = Int(timeInterval)
        return "\(timeStamp)"
    }
    
    /// 获取当前 毫秒级 时间戳 - 13位
    public  var milliStamp : String {
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let millisecond = CLongLong(round(timeInterval*1000))
        return "\(millisecond)"
    }
    
    /// 两个日期的时间差 (前大后小时间为负)
    /// - Parameters:
    ///   - other: 比对的时间
    ///   - Set<Calendar.Component>: 计算差的类型
    ///   - isSet: 是否重置时间到0点
    /// - Returns:
    public func dateComponents(date other:Date, components: Set<Calendar.Component>) -> DateComponents {
        let calendar:Calendar = Calendar(identifier: .gregorian)
        var newSelfDate = self
        var newOtherDate = other
        let diff:DateComponents = calendar.dateComponents(components, from: newSelfDate, to: newOtherDate)
        return diff
    }

}
 
