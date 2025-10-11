//
//  ApplePayLog.swift
//  Pods
//
//  Created by admin on 2025/8/12.
//


/// 步骤的内容
struct ApplePayProgressInfo {
    var type: ApplePayLog.ProgressType
    var title:String
    var des:String
    var date:Date
    
    func info() -> String {
        return "\(date.stringFmt(fmt: "yyyy.MM.dd HH:mm:ss:SSS"))  status:\(type.des())  content:\(title)-\(des)"
    }
}


class ApplePayLog: NSObject {
    
    enum ProgressType {
        /// 开始
        case start
        /// 购买状态改变
        case statusChange
        /// 结束
        case end
        /// 清理
        case clear
        /// 产品信息
        case product
    }
 
    private(set) var infoList:[ApplePayProgressInfo] = Array()
    
    func add(type:ProgressType, title:String, des:String) {
        infoList.append(.init(type: type, title: title, des: des, date: Date()))
    }
    
    func getInfo() -> [String] {
        let strList:[String] = infoList.compactMap { progress in
            return progress.info()
        }
        return strList
    }
    
}


private extension Date {
    
    func stringFmt(fmt: String) -> String{
        let dataFmt = DateFormatter()
        dataFmt.locale = Locale.init(identifier: "zh_CN")
        dataFmt.dateFormat = fmt;
        return dataFmt.string(from: self)
    }
    
}



extension ApplePay.PaymentType {
    /// 内容
    func des() -> String {
        switch self {
        case .purchase:
            return "购买中"
        case .restore:
            return "恢复购买"
        }
    }
}

extension ApplePay.ResultFailType {
    
    func des() -> String {
        switch self {
        case .buyCancel:
            return "取消购买"
        case .buyFail:
            return "购买失败"
        case .restoreCancel:
            return "取消恢复购买"
        case .restoreFail:
            return "恢复购买失败"
        case .noOrder:
            return "没有订单号"
        case .timeout:
            return "超时"
        case .cannotPayments:
            return "不允许程序内付费"
        case .other:
            return "其他问题"
        }
    }
}


extension ApplePayLog.ProgressType {
    
    func des() -> String {
        switch self {
        case .start:
            return "开始"
        case .statusChange:
            return "状态变更"
        case .end:
            return "结束"
        case .clear:
            return "清理"
        case .product:
            return "产品信息"
        }
    }
}

