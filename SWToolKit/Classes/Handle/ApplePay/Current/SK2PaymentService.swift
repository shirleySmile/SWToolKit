//
//  SK2PaymentService.swift
//  Pods
//
//  新版支付：使用 StoreKit 2 实现的苹果内购（能力下限 iOS 15）。
//

import StoreKit
import Foundation


/// 使用 StoreKit 2 实现的苹果内购
@MainActor
class SK2PaymentService: NSObject, ApplePayEngine {
    
    /// 当前支付类型 购买or恢复（仅用于日志）
    private var currPaymentType: ApplePayManager.PaymentType?
    
    /// 数据回调
    weak var engineDelegate: ApplePayEngineDelegate?
    
    /// 交易更新监听任务
    private var updatesTask: Task<Void, Never>?
    
    /// 购买任务
    private var purchaseTask: Task<Void, Never>?
    
    /// 恢复任务
    private var restoreTask: Task<Void, Never>?
    
    /// 订单映射（流程Id → 订单号），与 StoreKit 1 链路共用（appAccountToken 仅支持 UUID）
    private let orderStore: PaymentOrderStore
    
    /// 当前会话 Id（购买时同时作为 appAccountToken；nil = 空闲）
    private var currentSessionId: UUID?
    
    /// 恢复购买是否仍在苹果侧等待回调（超时释放会话锁后仍为 true，用于「恢复不并发」）
    private var restoreInFlight = false
    
    var isRestoreInFlight: Bool {
        return restoreInFlight
    }
    
    deinit {
        /// 取消交易队列监听
        updatesTask?.cancel()
        updatesTask = nil
    }
    
    nonisolated init(orderStore: PaymentOrderStore) {
        self.orderStore = orderStore
        super.init()
    }
    
    /// 是否已启动监听
    private var isStarted = false
    
    /// 注册观察者并开始监听交易更新
    func start() {
        guard !isStarted else { return }
        isStarted = true
        updatesTask = Task { [weak self] in
            await self?.listenForTransactionUpdates()
        }
        Task { [weak self] in
            await self?.handleUnfinishedTransactions()
        }
    }
    
    /// 检测是否可以使用内购
    func checkCanPayment() -> Bool {
        return AppStore.canMakePayments
    }
    
    /// 开始支付
    /// - Parameters:
    ///   - productId: 商品Id
    ///   - orderId: 业务订单号
    ///   - sessionId: 支付流程 Id，写入 appAccountToken，回调原样带回
    func startPay(productId: String, orderId: String, sessionId: UUID) {
        self.currPaymentType = .purchase
        self.currentSessionId = sessionId
        applePayLog.add(type: .start, title: "开始购买", des: "发送购买请求 流程Id:\(sessionId.uuidString) 订单:\(orderId) 商品:\(productId)")
        self.orderStore.insert(orderId: orderId, for: sessionId)
        self.purchaseTask = Task { [weak self] in
            await self?.fetchAndPurchase(productId: productId, sessionId: sessionId)
        }
    }
    
    /// 恢复购买
    func restore(sessionId: UUID) {
        self.currPaymentType = .restore
        self.currentSessionId = sessionId
        self.restoreInFlight = true
        applePayLog.add(type: .start, title: "开始恢复", des: "开始请求恢复数据 流程Id:\(sessionId.uuidString)")
        self.restoreTask = Task { [weak self] in
            await self?.restoreEntitlements(sessionId: sessionId)
        }
    }
    
    func cancel() {
        applePayLog.add(type: .end, title: "applePayment", des: "外部调用取消")
        self.purchaseTask?.cancel()
        self.restoreTask?.cancel()
        self.purchaseTask = nil
        self.restoreTask = nil
        self.restoreInFlight = false
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
    
    //MARK: ---------------购买-----------------
    
    /// 获取商品信息并发起购买
    private func fetchAndPurchase(productId: String, sessionId: UUID) async {
        do {
            let products = try await Product.products(for: [productId])
            guard let product = products.first else {
                applePayLog.add(type: .product, title: "产品回调", des: "苹果商品内购产品Id与用户申请购买Id不匹配")
                self.failResultHandle(type: .noOrder, msg: "没有找到指定商品", sessionId: sessionId, productId: productId)
                return
            }
            await self.purchase(product, sessionId: sessionId)
        } catch {
            /// 超时后的自身取消不算业务失败；真实失败（含迟到）照常上报
            if error is CancellationError { return }
            applePayLog.add(type: .product, title: "产品回调", des: "获取产品信息失败\(error.localizedDescription)")
            self.failResultHandle(type: .noOrder, msg: error.localizedDescription, sessionId: sessionId, productId: productId)
        }
    }
    
    /// 发起购买
    private func purchase(_ product: Product, sessionId: UUID) async {
        let result: Product.PurchaseResult
        do {
            result = try await product.purchase(options: [.appAccountToken(sessionId)])
        } catch {
            if error is CancellationError { return }
            applePayLog.add(type: .product, title: "产品回调", des: "发起购买失败\(error.localizedDescription)")
            self.failResultHandle(type: .buyFail, msg: error.localizedDescription, sessionId: sessionId, productId: product.id)
            return
        }
        switch result {
        case .success(let verificationResult):
            do {
                /// 校验交易凭证
                let transaction = try verificationResult.payloadValue
                await self.deliverVerifiedTransaction(transaction, fallbackSessionId: sessionId)
            } catch {
                /// 验证失败可能是设备时间/证书等临时问题，保留订单映射，等交易后续被重新验证时仍能匹配
                var callbackProductId = product.id
                if case .unverified(let transaction, _) = verificationResult {
                    callbackProductId = transaction.productID
                }
                self.failResultHandle(type: .buyFail, msg: error.localizedDescription,
                                      sessionId: sessionId, productId: callbackProductId, keepOrder: true)
            }
        case .userCancelled:
            /// 用户取消了购买
            self.failResultHandle(type: .buyCancel, msg: "交易已取消", sessionId: sessionId, productId: product.id)
        case .pending:
            /// 交易挂起，可能需要家长同意等（保留订单映射，晚到批准仍可发货）
            applePayLog.add(type: .statusChange, title: "购买事物变更", des: "交易延期 流程Id:\(sessionId.uuidString)")
            let pendingOrderId = self.orderStore.orderId(for: sessionId)
            self.clearSession(sessionId)
            self.callbackMain { $0.enginePending(self, sessionId: sessionId, productId: product.id, orderId: pendingOrderId) }
        @unknown default:
            self.failResultHandle(type: .other, msg: "未知问题", sessionId: sessionId, productId: product.id)
        }
    }
    
    //MARK: ---------------恢复购买-----------------
    
    /// 恢复购买
    private func restoreEntitlements(sessionId: UUID) async {
        /// StoreKit 2 的 currentEntitlements 只读本地缓存，换机/新装后必须显式同步才能拿到完整购买记录
        do {
            try await AppStore.sync()
        } catch {
            if error is CancellationError { return }
            self.restoreInFlight = false
            if let storeError = error as? StoreKitError, case .userCancelled = storeError {
                self.failResultHandle(type: .restoreCancel, msg: "用户取消恢复购买", sessionId: sessionId)
            } else {
                self.failResultHandle(type: .restoreFail, msg: error.localizedDescription, sessionId: sessionId)
            }
            return
        }
        var hasEntitlement = false
        /// 遍历用户当前的所有权益（已购买且未退款的有效非消耗型商品和订阅）
        for await result in Transaction.currentEntitlements {
            if (try? result.payloadValue) != nil {
                hasEntitlement = true
            }
        }
        /// 恢复结果已产生，先解除「恢复不并发」限制再回调
        self.restoreInFlight = false
        if hasEntitlement {
            let info = AppReceipt.read()
            if let receiptStr = info.receiptStr {
                applePayLog.add(type: .end, title: "恢复购买", des: "本地有票据 流程Id:\(sessionId.uuidString)")
                /// 先清理会话再回调，避免上层在回调里立即发起新操作时被清掉
                self.clearSession(sessionId)
                self.callbackMain { delegate in
                    delegate.engineRestore(self, sessionId: sessionId, receipt: receiptStr)
                }
            } else {
                self.failResultHandle(type: .restoreFail, msg: info.msg, sessionId: sessionId)
            }
        } else {
            /// 没有可恢复的购买项
            self.failResultHandle(type: .restoreFail, msg: "没有可恢复的购买项", sessionId: sessionId)
        }
    }
    
    //MARK: ---------------交易更新监听-----------------
    
    /// 监听交易更新（用于处理例如应用在购买过程中被挂起后恢复的场景）
    private func listenForTransactionUpdates() async {
        for await update in Transaction.updates {
            switch update {
            case .verified(let transaction):
                applePayLog.add(type: .statusChange, title: "购买事物变更", des: "监听到交易更新(\(transaction.productID))")
                await self.deliverVerifiedTransaction(transaction)
            case .unverified(_, let error):
                applePayLog.add(type: .statusChange, title: "购买事物变更", des: "未验证交易(\(error.localizedDescription))")
            }
        }
    }
    
    /// 处理启动时未完成的事务（购买完成但未 finish 的场景）
    private func handleUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            if let transaction = try? result.payloadValue {
                await self.deliverVerifiedTransaction(transaction)
            }
        }
    }
    
    /// 已发货的交易（防止 purchase 结果与 Transaction.updates / unfinished 监听对同一交易重复发货）
    private var deliveredTransactionIDs: Set<UInt64> = []
    
    /// 处理已验证事务：能关联到本 App 发起的订单则带订单号发货；
    /// 无关联订单的交易（AppStore 促销购买、本地订单记录丢失等）orderId 传空发货，与 StoreKit 1 路径行为一致
    /// - Parameter fallbackSessionId: 仅由主动购买（purchase 结果）传入。交易监听/unfinished 不传，
    ///   避免促销、家庭共享等无 appAccountToken 的交易抢走进行中订单的订单号
    private func deliverVerifiedTransaction(_ transaction: StoreKit.Transaction, fallbackSessionId: UUID? = nil) async {
        /// 自动续费（续订，非首次购买）：不发货，仅结束
        if transaction.productType == .autoRenewable && transaction.originalID != transaction.id {
            applePayLog.add(type: .statusChange, title: "购买事物变更", des: "自动续费续订，不发货")
            await transaction.finish()
            return
        }
        /// 同一交易可能同时从 purchase 结果与交易监听中拿到，防止重复发货
        guard !deliveredTransactionIDs.contains(transaction.id) else {
            await transaction.finish()
            return
        }
        deliveredTransactionIDs.insert(transaction.id)
        /// 流程 Id 优先取苹果带回的 appAccountToken；主动购买允许回退到本次会话
        let sessionId = transaction.appAccountToken ?? fallbackSessionId
        /// 撤销/退款/家庭共享移除：不发货、不清理进行中的会话，仅通知上层记录
        if transaction.revocationDate != nil {
            let revokedOrderId = sessionId.flatMap { self.orderStore.orderId(for: $0) }
            applePayLog.add(type: .statusChange, title: "购买事物变更",
                            des: "交易被撤销 交易Id:\(transaction.id) 流程Id:\(sessionId?.uuidString ?? "-")")
            self.callbackMain { delegate in
                delegate.engineFail(self, sessionId: sessionId, productId: transaction.productID,
                                    orderId: revokedOrderId, type: .revoked, message: "交易被撤销")
            }
            await transaction.finish()
            return
        }
        let orderId: String?
        if let sessionId {
            orderId = self.orderStore.removeOrderId(for: sessionId)
        } else {
            /// 无关联订单（如 AppStore 促销点击购买）：orderId 为空发货
            orderId = nil
        }
        let info = AppReceipt.read()
        applePayLog.add(type: .end, title: info.receiptStr != nil ? "购买新产品" : "票据缺失",
                        des: "交易Id:\(transaction.id) 流程Id:\(sessionId?.uuidString ?? "-") 订单:\(orderId ?? "-") 商品:\(transaction.productID)")
        /// 先清理会话再回调：上层可能在回调里立即发起下一笔
        self.clearSession(sessionId)
        if let receiptStr = info.receiptStr {
            self.callbackMain { delegate in
                delegate.engineSuccess(self, sessionId: sessionId, productId: transaction.productID,
                                       orderId: orderId, receipt: receiptStr)
            }
        } else {
            self.callbackMain { delegate in
                delegate.engineFail(self, sessionId: sessionId, productId: transaction.productID,
                                    orderId: orderId, type: .buyFail, message: info.msg)
            }
        }
        await transaction.finish()
    }
    
    //MARK: ---------------结果处理-----------------
    
    /// 结果处理并将支付结果返回给调用端
    /// - Parameter keepOrder: true 时保留订单映射（验签失败等，交易稍后会被重新验证）
    private func failResultHandle(type: ApplePayManager.ResultFailType,
                                  msg: String,
                                  sessionId: UUID? = nil,
                                  productId: String? = nil,
                                  keepOrder: Bool = false) {
        applePayLog.add(type: .end,
                        title: (currPaymentType?.des() ?? "未知") + "失败",
                        des: "\(type.des()):\(msg) 流程Id:\(sessionId?.uuidString ?? "-") 商品:\(productId ?? "-")")
        let orderId = sessionId.flatMap { self.orderStore.orderId(for: $0) }
        if let sessionId, !keepOrder {
            self.orderStore.remove(for: sessionId)
        }
        self.clearSession(sessionId)
        self.callbackMain { delegate in
            delegate.engineFail(self, sessionId: sessionId, productId: productId,
                                orderId: orderId, type: type, message: msg)
        }
    }
    
    /// 保证代理回调在主线程执行（类已 @MainActor，直接回调）
    private func callbackMain(_ block: @escaping (ApplePayEngineDelegate) -> Void) {
        guard let delegate = self.engineDelegate else { return }
        block(delegate)
    }
    
}
