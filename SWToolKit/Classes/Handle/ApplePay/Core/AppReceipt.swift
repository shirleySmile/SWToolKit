//
//  AppReceipt.swift
//  Pods
//
//  本地购买凭证读取。纯 Foundation 实现，Core 里唯一和票据文件相关的地方。
//

import Foundation


enum AppReceipt {

    /// 读取本地购买凭证（App Store 收据文件）
    static func read() -> (msg: String, receiptStr: String?) {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            return ("没有购买凭证", nil)
        }
        do {
            let receiptData = try Data(contentsOf: receiptURL)
            let encodeStr = receiptData.base64EncodedString()
            if encodeStr.count > 0 {
                return ("苹果内购成功获取数据", encodeStr)
            } else {
                return ("苹果服务器解析出错", nil)
            }
        } catch {
            return (error.localizedDescription, nil)
        }
    }

    /// 读取本地购买凭证并记录日志
    static func readAndLog() -> (msg: String, receiptStr: String?) {
        let info = read()
        if info.receiptStr != nil {
            applePayLog.add(type: .end, title: "获取本地票据", des: "本地有票据")
        } else {
            applePayLog.add(type: .end, title: "获取本地票据", des: "本地无票据\(info.msg)")
        }
        return info
    }

}
