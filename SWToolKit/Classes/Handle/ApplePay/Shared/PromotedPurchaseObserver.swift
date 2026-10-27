//
//  PromotedPurchaseObserver.swift
//  Pods
//
//  App Store 商品页“促销购买”的入口。
//
//  说明：StoreKit 2 没有提供接收促销购买的 API，苹果现行做法仍然是实现
//  SKPaymentTransactionObserver 的这个代理方法。它只负责“接不接受这笔”，
//  交易本体由各引擎自己的监听负责，因此这里不处理、也不 finish 任何交易，
//  避免抢在引擎监听之前把交易结束掉。
//

import Foundation
import StoreKit


@MainActor
final class PromotedPurchaseObserver: NSObject {

    /// 由 ApplePayManager 强持有，这里弱引用避免循环
    weak var manager: ApplePayManager?

    /// 是否已注册观察者
    private var isStarted = false

    deinit {
        SKPaymentQueue.default().remove(self)
    }

    /// 注册观察者（整个进程只注册一次）
    func start() {
        guard !isStarted else { return }
        isStarted = true
        SKPaymentQueue.default().add(self)
    }

}


extension PromotedPurchaseObserver: @preconcurrency SKPaymentTransactionObserver {

    /// 只负责促销购买入口，交易统一由各引擎自己的监听处理
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {}

    /// 当用户从 App Store 商品页发起促销购买时发送此消息
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return manager?.shouldAcceptPromotedPurchase() ?? false
    }

}
