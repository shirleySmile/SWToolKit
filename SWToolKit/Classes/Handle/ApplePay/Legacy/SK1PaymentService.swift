//
//  SK1PaymentService.swift
//  Pods
//
//  旧版支付：使用 StoreKit 1 实现的苹果内购。
//  与新版代码完全独立，后续可整体删除。
//

import StoreKit
import Foundation


/// 使用 StoreKit 1 实现的苹果内购
@MainActor
class SK1PaymentService: NSObject, ApplePayEngine {
    
    /// 当前支付类型 购买or恢复（仅用于日志）
    private var currPaymentType: ApplePayManager.PaymentType?
    
    /// 苹果产品信息
    private let productCache: SK1ProductCache = .init()
    
    /// 订单映射（流程Id → 订单号），与 StoreKit 2 链路共用
    private let orderStore: PaymentOrderStore
    
    /// 当前会话 Id（购买时写入 applicationUsername；nil = 空闲）
    private var currentSessionId: UUID?
    
    /// 当前恢复会话 Id
    private var restoreSessionId: UUID?
    
    /// 恢复购买是否仍在苹果侧等待回调（超时释放会话锁后仍为 true，用于「恢复不并发」）
    private var restoreInFlight = false
    
    /// 数据回调
    weak var engineDelegate: ApplePayEngineDelegate?
    
    deinit {
        /// 删除一个交易队列观察者
        SKPaymentQueue.default().remove(self)
    }
    
    init(orderStore: PaymentOrderStore) {
        self.orderStore = orderStore
        super.init()
    }
    
    /// 是否已注册观察者
    private var isStarted = false
    
    /// 恢复购买是否仍在苹果侧等待回调
    var isRestoreInFlight: Bool {
        return restoreInFlight
    }
    
    /// 注册交易队列观察者
    func start() {
        guard !isStarted else { return }
        isStarted = true
        SKPaymentQueue.default().add(self)
    }
    
    /// 检测是否可以使用内购
    func checkCanPayment() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    /// 开始支付
    /// - Parameters:
    ///   - productId: 商品Id
    ///   - orderId: 业务订单号
    ///   - sessionId: 支付流程 Id，写入 applicationUsername，回调原样带回
    func startPay(productId: String, orderId: String, sessionId: UUID) {
        self.currPaymentType = .purchase
        self.currentSessionId = sessionId
        applePayLog.add(type: .start, title: "开始购买", des: "发送购买请求 流程Id:\(sessionId.uuidString) 订单:\(orderId) 商品:\(productId)")
        self.orderStore.insert(orderId: orderId, for: sessionId)
        self.productCache.getProducts(productId: productId) { [weak self] product in
            guard let self else { return }
            guard let product else {
                self.failResultHandle(type: .noOrder, msg: "没有找到指定商品", sessionId: sessionId, productId: productId)
                return
            }
            // 添加一个交易队列观察者
            let payment = SKMutablePayment(product: product)
            /// 流程 Id 写入 applicationUsername，苹果回调原样带回，用于反查订单号
            payment.applicationUsername = sessionId.uuidString
            SKPaymentQueue.default().add(payment)
        }
    }
    
    /// 恢复购买
    func restore(sessionId: UUID) {
        self.currPaymentType = .restore
        self.currentSessionId = sessionId
        self.restoreSessionId = sessionId
        self.restoreInFlight = true
        applePayLog.add(type: .start, title: "开始恢复", des: "开始请求恢复数据 流程Id:\(sessionId.uuidString)")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func cancel() {
        applePayLog.add(type: .end, title: "applePayment", des: "外部调用取消")
        self.productCache.cancel()
        self.restoreInFlight = false
        self.restoreSessionId = nil
        self.currPaymentType = nil
        self.currentSessionId = nil
    }
    
    /// 仅当回调属于当前会话时清理引擎内部状态，
    /// 避免迟到回调把新会话的流程 Id 抹掉
    private func clearSession(_ sessionId: UUID?) {
        guard sessionId != nil, sessionId == self.currentSessionId else { return }
        self.currPaymentType = nil
        self.currentSessionId = nil
    }
    
}


extension SK1PaymentService {
    
    /// 从 applicationUsername 解析流程 Id 并反查订单号
    /// - UUID 且映射存在：本次/历史流程，返回流程 Id 与订单号
    /// - UUID 但映射不存在：过期/迟到流程，订单号返回空
    /// - 非 UUID：老版本交易，整串就是订单号
    /// - 为空：App Store 促销交易
    /// - Parameter removeOrder: false 时只读订单号不删除（发货失败时交易要保留重试，映射不能先丢）
    private func resolveSession(_ transaction: SKPaymentTransaction, removeOrder: Bool = true) -> (sessionId: UUID?, orderId: String?) {
        guard let raw = transaction.payment.applicationUsername else { return (nil, nil) }
        guard let sessionId = UUID(uuidString: raw) else { return (nil, raw) }
        let orderId = removeOrder ? self.orderStore.removeOrderId(for: sessionId) : self.orderStore.orderId(for: sessionId)
        return (sessionId, orderId)
    }
    
    // 交易结束,当交易结束后还要去appstore上验证支付信息是否都正确,只有所有都正确后,我们就可以给用户方法我们的虚拟物品了。
    /// - Returns: 是否已投递宿主；false 时调用方不得 finish 交易
    private func completeTransaction(_ transaction: SKPaymentTransaction) -> Bool {
        /// 先只读订单映射；确认成功交付后才删除（票据缺失/投递失败时交易要保留重试）
        let parsed = self.resolveSession(transaction, removeOrder: false)
        let receptInfo = AppReceipt.read()
        guard let receiptStr = receptInfo.receiptStr else {
            /// 票据读取失败：交易不 finish、订单映射不删，否则用户已付款却永远拿不到货；
            /// 交易保持在队列中，下次启动会重新投递
            applePayLog.add(type: .end, title: "票据缺失",
                            des: "交易Id:\(transaction.transactionIdentifier ?? "-") 保留交易待重试 流程Id:\(parsed.sessionId?.uuidString ?? "-") 订单:\(parsed.orderId ?? "-")")
            self.failResultHandle(type: .buyFail, msg: receptInfo.msg,
                                  sessionId: parsed.sessionId, productId: transaction.payment.productIdentifier,
                                  orderId: parsed.orderId)
            return false
        }
        applePayLog.add(type: .end, title: "购买新产品",
                        des: "本地有票据 交易Id:\(transaction.transactionIdentifier ?? "-") 流程Id:\(parsed.sessionId?.uuidString ?? "-") 订单:\(parsed.orderId ?? "-") 商品:\(transaction.payment.productIdentifier)")
        /// 先清理会话再回调，避免上层在回调里立即发起新操作时被清掉
        self.clearSession(parsed.sessionId)
        let delivered = self.engineDelegate?.engineSuccess(self, sessionId: parsed.sessionId,
                                                           productId: transaction.payment.productIdentifier,
                                                           orderId: parsed.orderId, receipt: receiptStr) ?? false
        guard delivered else {
            /// 宿主代理为空未投递：保留交易与订单映射，等待下次启动重试
            applePayLog.add(type: .end, title: "投递失败", des: "宿主代理为空，保留交易待重试 交易Id:\(transaction.transactionIdentifier ?? "-")")
            return false
        }
        /// 投递成功才消费订单映射
        if let sessionId = parsed.sessionId {
            _ = self.orderStore.removeOrderId(for: sessionId)
        }
        return true
    }
    
    /// 购买失败
    private func failedTransaction(_ transaction: SKPaymentTransaction) {
        var msg = ""
        var type: ApplePayManager.ResultFailType = .buyFail
        if let error = transaction.error as? SKError, error.code != .paymentCancelled {
            msg = error.localizedDescription
        } else {
            type = .buyCancel
            msg = "交易已取消"
        }
        let (sessionId, orderId) = self.resolveSession(transaction)
        self.failResultHandle(type: type, msg: msg, sessionId: sessionId,
                              productId: transaction.payment.productIdentifier, orderId: orderId)
    }
    
    /// 结果处理并将支付结果返回给调用端
    private func failResultHandle(type: ApplePayManager.ResultFailType, msg: String,
                                  sessionId: UUID? = nil, productId: String? = nil, orderId: String? = nil) {
        applePayLog.add(type: .end,
                        title: (currPaymentType?.des() ?? "未知") + "失败",
                        des: "\(type.des()):\(msg) 流程Id:\(sessionId?.uuidString ?? "-") 商品:\(productId ?? "-") 订单:\(orderId ?? "-")")
        self.clearSession(sessionId)
        self.engineDelegate?.engineFail(self, sessionId: sessionId, productId: productId,
                                        orderId: orderId, type: type, message: msg)
    }
    
}


//MARK: ---------------SKPaymentTransactionObserver-----------------
extension SK1PaymentService: @preconcurrency SKPaymentTransactionObserver {
    
    // 恢复成功后的回调
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        /// 恢复结果已产生，先解除「恢复不并发」限制
        self.restoreInFlight = false
        let sessionId = self.restoreSessionId
        /// 说明有可恢复购买的产品
        if let receiptURL = Bundle.main.appStoreReceiptURL, FileManager.default.fileExists(atPath: receiptURL.path) {
            let receptInfo = AppReceipt.read()
            if let receiptStr = receptInfo.receiptStr {
                applePayLog.add(type: .end, title: "恢复购买", des: "本地有票据 流程Id:\(sessionId?.uuidString ?? "-")")
                /// 先清理会话再回调，避免上层在回调里立即发起新操作时被清掉
                self.clearSession(sessionId)
                self.restoreSessionId = nil
                self.engineDelegate?.engineRestore(self, sessionId: sessionId, receipt: receiptStr)
            } else {
                self.restoreSessionId = nil
                self.failResultHandle(type: .restoreFail, msg: receptInfo.msg, sessionId: sessionId)
            }
        } else {
            // 没有可恢复的购买项
            self.restoreSessionId = nil
            self.failResultHandle(type: .restoreFail, msg: "没有可恢复的购买项", sessionId: sessionId)
        }
    }
    
    // 恢复失败后的回调
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        /// 恢复结果已产生，先解除「恢复不并发」限制
        self.restoreInFlight = false
        let sessionId = self.restoreSessionId
        self.restoreSessionId = nil
        // 没有可恢复的购买项
        var msg: String = ""
        var type: ApplePayManager.ResultFailType = .restoreFail
        if let error = error as? SKError, error.code != .paymentCancelled {
            msg = error.localizedDescription
        } else {
            type = .restoreCancel
            msg = "用户取消交易"
        }
        self.failResultHandle(type: type, msg: msg, sessionId: sessionId)
    }
    
    // 支付状态变更
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        let info: [String] = transactions.compactMap({ trans in
            return trans.description
        })
        applePayLog.add(type: .statusChange, title: "购买事物变更", des: "回调信息(" + info.toJson() + ")")
        for trans in transactions {
            switch trans.transactionState {
            case .purchasing:
                applePayLog.add(type: .statusChange, title: "购买事物变更", des: "商品添加进列表")
            case .purchased:
                if trans.original != nil {
                    applePayLog.add(type: .statusChange, title: "购买事物变更", des: "自动续费的订单")
                    SKPaymentQueue.default().finishTransaction(trans)
                } else {
                    if trans.payment.applicationUsername == nil {
                        // AppStore 促销购买，发货，orderId 为空
                        applePayLog.add(type: .statusChange, title: "购买事物变更", des: "AppStore 促销购买")
                    } else {
                        // 主动购买，发货
                        applePayLog.add(type: .statusChange, title: "购买事物变更", des: "一次购买交易完成")
                    }
                    /// 只有成功投递宿主后才结束交易；票据缺失或宿主代理为空时保留交易，等待下次启动重试
                    if completeTransaction(trans) {
                        SKPaymentQueue.default().finishTransaction(trans)
                    }
                }
            case .failed:
                applePayLog.add(type: .statusChange, title: "购买事物变更", des: "交易失败")
                failedTransaction(trans)
                SKPaymentQueue.default().finishTransaction(trans)
            case .restored:
                applePayLog.add(type: .statusChange, title: "购买事物变更", des: "恢复购买")
                SKPaymentQueue.default().finishTransaction(trans)
            case .deferred:
                applePayLog.add(type: .statusChange, title: "购买事物变更", des: "交易延期")
                /// 保留订单映射，等待批准后仍可发货；先解除会话锁
                let sessionId = UUID(uuidString: trans.payment.applicationUsername ?? "")
                let pendingOrderId = sessionId.flatMap { self.orderStore.orderId(for: $0) }
                self.clearSession(sessionId)
                self.engineDelegate?.enginePending(self, sessionId: sessionId,
                                                   productId: trans.payment.productIdentifier,
                                                   orderId: pendingOrderId)
            default:
                applePayLog.add(type: .statusChange, title: "购买事物变更", des: "其他情况(\(trans.transactionState.rawValue)")
                let (sessionId, orderId) = self.resolveSession(trans)
                failResultHandle(type: .other, msg: "未知问题:\(trans.transactionState.rawValue)",
                                 sessionId: sessionId, productId: trans.payment.productIdentifier,
                                 orderId: orderId)
                SKPaymentQueue.default().finishTransaction(trans)
            }
        }
    }
}
