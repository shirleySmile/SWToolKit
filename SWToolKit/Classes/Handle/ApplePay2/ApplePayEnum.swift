//
//  ApplePayEnum.swift
//  Pods
//
//  Created by admin on 2025/8/12.
//

import Foundation

public extension ApplePayManager {
    
    /// 支付结果错误的类型
    enum ResultFailType:Int {
        /// 用户取消购买
        case buyCancel
        /// 用户购买失败
        case buyFail
        
        /// 用户取消恢复购买
        case restoreCancel
        /// 用户恢复购买失败
        case restoreFail
        
        /// 有商品Id，但是苹果内购中无商品
        case noOrder
        /// 购买超时
        case timeout
        
        /// 其他 (未知错误)
        case other
        
    }

    /// 开始支付时错误的类型
    enum StartFailType:Int {
        /// 购买的产品Id为空
        case productIdNull
        /// 正在购买新内容
        case purchasing
        /// 正在恢复购买
        case restoring
        /// 不可进行购买
        case cannotPayments
    }
    
    /// 支付状态
    enum PaymentType:Int {
        /// 购买
        case purchase
        /// 恢复购买
        case restore
    }
    
}

