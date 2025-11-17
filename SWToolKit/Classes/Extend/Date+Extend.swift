//
//  DateExtend.swift
//  SWToolKit
//
//  Created by shirley on 2022/2/22.
//

import Foundation


extension Date {
    
    /// 下一个小时
    public var nextHour: Date? {
        return Calendar.current.nextDate(after: self, matching: DateComponents(minute: 0), matchingPolicy: .strict)
    }
    /// 下一秒钟
    public var nextSecond: Date? {
        return Calendar.current.nextDate(after: self, matching: DateComponents(nanosecond: 0), matchingPolicy: .strict)
    }
    /// 下一分钟
    public var nextMinute: Date? {
        return Calendar.current.nextDate(after: self, matching: DateComponents(second: 0), matchingPolicy: .strict)
    }
    /// 明天
    public var nextDay: Date? {
        return Calendar.current.nextDate(after: self, matching: DateComponents(hour:0), matchingPolicy: .strict)
    }
    /// 下一个月初
    public var nextMonth: Date? {
        return Calendar.current.nextDate(after: self, matching: DateComponents(day:1), matchingPolicy: .strict)
    }
    /// 明年
    public var nextYear: Date? {
        return Calendar.current.nextDate(after: self, matching: DateComponents(month: 1), matchingPolicy: .strict)
    }
    
    
    
    public var year: Int {
        Calendar.current.component(.year, from: self)
    }
    public var month: Int {
        Calendar.current.component(.month, from: self)
    }
    /// 当月第几天
    public var day: Int {
        Calendar.current.component(.day, from: self)
    }
    public var hour: Int {
        Calendar.current.component(.hour, from: self)
    }
    public var minute: Int {
        Calendar.current.component(.minute, from: self)
    }
    public var second: Int {
        Calendar.current.component(.second, from: self)
    }
    public var nanosecond: Int {
        Calendar.current.component(.nanosecond, from: self)
    }
    /// 美国星期 1:周日。2:周一 3:周二 4:周三 5:周四 6:周五 7:周六
    public var weekday:Int {
        Calendar.current.component(.weekday, from: self)
    }
    /// 当年的第几周
    public var weekOfYear:Int {
        Calendar.current.component(.weekOfYear, from: self)
    }
    
    /// 当年的第几天
    public var dayOfYear:Int {
        if #available(iOS 18, *) {
            return Calendar.current.component(.dayOfYear, from: self)
        } else {
            var res = 0, monthArr = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
            let time = self.string(format:"yyyy-MM-dd").split(separator: "-"), y = Int(time[0])!, m = Int(time[1])!, d = Int(time[2])!
            if y % 400 == 0 || (y % 4 == 0 && y % 100 != 0) {
                monthArr[1] = 29
            }
            for i in 0 ..< m - 1 {
                res += monthArr[i]
            }
            return res + d
        }
    }
    
    /// 中国星期 1:周一 2:周二 3:周三 4:周四 5:周五 6:周六 7:周日
    public var cnWeekDay:Int{
        var week = self.weekday - 1
        if week == 0 {
            week = 7
        }
        return week
    }
    
    /// 日期中的月份共几个星期
    public func weeksOfMonth() -> Int {
        let calendar:Calendar = Calendar(identifier: .gregorian)
        let weekRange = calendar.range(of: .weekOfMonth, in: .month, for: self)
        let weeksCount = weekRange?.count ?? 0
        return weeksCount
    }
    
    
    /// 日期中的月份共有几天
    public func daysOfMonth() -> Int {
        let year = self.year
        let month = self.month
        switch month {
        case 1, 3, 5, 7, 8, 10, 12:
            return 31
        case 2:
            let isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
            return isLeapYear ? 29 : 28
        default:
            return 30
        }
    }
    
    /// 日期中的年的总天数
    public func daysOfYear() -> Int{
        let year = self.year
        let isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
        return isLeapYear ? 366 : 365
    }
    
}


extension Date {
    
    public var isToday: Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(self)
    }
    
    public var isLeapYear: Bool {
        return (self.daysOfYear() == 366)
    }
    
}


//MARK: 杂七杂八
extension Date {
    
    /// 日期转字符串
    public func string(format fmt:String, locale:String? = "en_GB") -> String {
        let dateFmt = DateFormatter()
        if let locale = locale, locale.count > 0 {
            dateFmt.locale = Locale.init(identifier: locale)
        }
        dateFmt.dateFormat = fmt;
        return dateFmt.string(from: self)
    }
    
    /// 字符串转日期
    public static func date(format fmt:String, str:String, locale:String? = "en_GB") -> Date {
        let dataFmt = DateFormatter()
        if let locale = locale, locale.count > 0 {
            dataFmt.locale = Locale.init(identifier: locale)
        }
        dataFmt.dateFormat = fmt
        let date = dataFmt.date(from: str)
        return date ?? Date.init()
    }
         

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
    
    
}
 

//MARK: 两个时间的比较
extension Date {
    
    
    /// 计算两个日期相差多少天
    /// - Parameters:
    ///   - startDate: 开始
    ///   - endDate: 结束
    /// - Returns: 返回天数
    public func betweenDays(by other:Date) -> Int {
          let calendar = Calendar.current
          let fmt = "yyyy-MM-dd"
            let dateA:Date = self.changeNewDate(fmt: fmt)
            let dateB:Date = other.changeNewDate(fmt: fmt)
            let diff:DateComponents = calendar.dateComponents([.day], from: dateA, to: dateB)
          return diff.day!
    }

    
    /// 获取指定时间前或者后的时间（年月日）
    /// - Parameters:
    ///   - year: 年间隔
    ///   - month: 月间隔
    ///   - day: 日间隔
    ///   - hour: 时间间隔
    ///   - minute: 分钟间隔
    ///   - second: 秒钟
    /// - Returns: 返回相应的时间
    func getLaterDateFromDate(year:Int,month:Int,day:Int,hour:Int,minute:Int,second:Int) -> Date {
        let calendar:Calendar = Calendar.current
        let adcomps = NSDateComponents()
        adcomps.year = year
        adcomps.month = month
        adcomps.day = day
        adcomps.hour = hour
        adcomps.minute = minute
        adcomps.second = second
        let newdate = calendar.date(byAdding: adcomps as DateComponents, to: self, wrappingComponents: false)
        return newdate!
    }
    
    
    /// 比较两个时间大小   -1:开始时间大于结束时间    0:开始时间等于结束时间    1:开始时间小于结束时间
    /// - Parameters:
    ///   - startDate: 开始时间
    ///   - endDate: 结束时间
    /// - Returns: 结果
    public func compare(by other:Date, fmt:String?) -> Int {
        let startD = self.changeNewDate(fmt: fmt).timeIntervalSince1970
        let stopD =  other.changeNewDate(fmt: fmt).timeIntervalSince1970
        return (startD > stopD) ? -1 : (startD <  stopD ? 1 : 0)
    }

    /// 两个日期的时间差 (前大后小时间为负)
    /// - Parameters:
    ///   - other: 比对的时间
    ///   - Set<Calendar.Component>: 计算差的类型
    ///   - isSet: 是否重置时间到0点
    /// - Returns:
    public func dateComponents(by other:Date, fmt:String? = nil, components: Set<Calendar.Component>) -> DateComponents {
        let calendar:Calendar = Calendar.current   ///Calendar(identifier: .gregorian)
        let dateA:Date = self.changeNewDate(fmt: fmt)
        let dateB:Date = other.changeNewDate(fmt: fmt)
        let diff:DateComponents = calendar.dateComponents(components, from: dateA, to: dateB)
        return diff
    }

    /// 是否为同天
    /// - Parameters:
    ///   - date: 比对的日期
    ///   - reset: 重置到0点
    public func theSameDay(by other:Date, reset:Bool = true) -> Bool {
        let fmt:String? = (reset ? "yyyy-MM-dd" : nil)
        let dateA:Date = self.changeNewDate(fmt: fmt)
        let dateB:Date = other.changeNewDate(fmt: fmt)
        let calendar = Calendar.current
        let componentsA:DateComponents = calendar.dateComponents([.year, .month, .day], from: dateA)
        let componentsB:DateComponents = calendar.dateComponents([.year, .month, .day], from: dateB)
        return componentsA.year == componentsB.year && componentsA.month == componentsB.month && componentsA.day == componentsB.day
    }
    
    /// 是否在同一个星期
    /// - Parameters:
    ///   - date: 比对的日期
    ///   - reset: 重置到0点
    public func theSameWeek(by other:Date, reset:Bool = true) -> Bool {
        let fmt:String? = (reset ? "yyyy-MM-dd" : nil)
        let dateA:Date = self.changeNewDate(fmt: fmt)
        let dateB:Date = other.changeNewDate(fmt: fmt)
        let calendar = Calendar.current
        let componentsA:DateComponents = calendar.dateComponents([.weekOfYear], from: dateA)
        let componentsB:DateComponents = calendar.dateComponents([.weekOfYear], from: dateB)
        return componentsA.weekOfYear == componentsB.weekOfYear
    }
    
    /// 是否在同一个月
    /// - Parameters:
    ///   - date: 比对的日期
    ///   - reset: 重置到0点
    public func theSameMonth(by other:Date, reset:Bool = true) -> Bool {
        let fmt:String? = (reset ? "yyyy-MM-dd" : nil)
        let dateA:Date = self.changeNewDate(fmt: fmt)
        let dateB:Date = other.changeNewDate(fmt: fmt)
        let calendar = Calendar.current
        let componentsA:DateComponents = calendar.dateComponents([.year, .month], from: dateA)
        let componentsB:DateComponents = calendar.dateComponents([.year, .month], from: dateB)
        return (componentsA.year == componentsB.year && componentsA.month == componentsB.month)
    }
    
    /// 是否在两个之间之内
    /// - Parameters:
    ///   - start: 开始时间
    ///   - end: 结束时间
    ///   - fmt: Format
    public func between(in start:Date, _ end:Date, fmt:String?) -> Bool {
        let date = self.changeNewDate(fmt: fmt)
        let startD = start.changeNewDate(fmt: fmt)
        let endD = end.changeNewDate(fmt: fmt)
        if date.compare(startD) == .orderedAscending {
            return false
        }
        if date.compare(endD) == .orderedDescending {
            return false
        }
        return true
    }
    
}



//MARK: 时间戳
extension Date {
    
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
    public static func getTimeFromtimeStamp(timeStamp: Double,format:String = "yyyy-MM-dd HH:mm:ss") -> String {
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
    public var milliStamp : String {
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let millisecond = CLongLong(round(timeInterval*1000))
        return "\(millisecond)"
    }
    
}





extension Date {
    
    func changeNewDate(fmt:String?) -> Date {
        guard let fmt else { return self }
        return Date.date(format: fmt, str: self.string(format: fmt))
    }
    
    
}
