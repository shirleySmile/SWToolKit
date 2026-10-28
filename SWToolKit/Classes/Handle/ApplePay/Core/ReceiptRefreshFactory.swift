//
//  ReceiptRefreshFactory.swift
//  Pods
//
//  票据刷新实现选择：这里只根据开关返回新/旧实现，不判断系统版本。
//

import Foundation


enum ReceiptRefreshFactory {

    /// 根据开关创建票据刷新服务
    /// - Parameter mode: 新实现（AppStore.sync）或旧实现（SKReceiptRefreshRequest）
    static func make(mode:ApplePayManager.ReceiptRefreshMode) -> ReceiptRefreshService {
        switch mode {
        case .new:
            return StoreKit2ReceiptRefreshService()
        case .legacy:
            return StoreKit1ReceiptRefreshService()
        }
    }

}
