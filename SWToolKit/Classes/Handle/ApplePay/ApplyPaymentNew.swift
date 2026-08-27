//
//  ApplyPaymentNew.swift
//  Pods
//
//  Created by muwa on 2025/10/27.
//

import StoreKit
import Foundation


/// 订单映射记录（token → 订单号，附带创建时间用于过期清理）
private struct OrderRecord: Codable {
    let orderId: String
    let createdAt: Date
}


/// 使用 StoreKit 2 实现的苹果内购（iOS 15 ~ 25 使用）
@MainActor
class ApplyPaymentNew: NSObject, ApplePayService {
    
    /// 当前支付类型 购买or恢复
    private var currPaymentType: ApplePayManager.PaymentType?
    
    /// 数据回调
    weak var serviceDelegate: ApplePayServiceDelegate?
    
    /// 交易更新监听任务
    private var updatesTask: Task<Void, Never>?
    
    /// 购买任务
    private var purchaseTask: Task<Void, Never>?
    
    /// 恢复任务
    private var restoreTask: Task<Void, Never>?
    
    /// 订单号与 token 的映射（StoreKit 2 的 appAccountToken 仅支持 UUID）
    private var orderMap: [UUID: OrderRecord] = [:]
    
    /// 当前购买使用的 token
    private var currentOrderToken: UUID?
    
    deinit {
        /// 删除交易队列观察者
        SKPaymentQueue.default().remove(self)
        updatesTask?.cancel()
        updatesTask = nil
    }
    
    nonisolated override init() {
        super.init()
        self.orderMap = Self.loadOrderMap()
    }
    
    /// 是否已启动监听
    private var isStarted = false
    
    /// 注册观察者并开始监听交易更新
    func start() {
        guard !isStarted else { return }
        isStarted = true
        SKPaymentQueue.default().add(self)
        updatesTask = Task { [weak self] in
            await self?.listenForTransactionUpdates()
        }
        Task { [weak self] in
            await self?.handleUnfinishedTransactions()
        }
    }
    
    /// 检测是否可以使用内购
    func checkCanPayment() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    /// 开始支付
    /// - Parameters:
    ///   - productId: 商品Id
    ///   - orderId: 订单Id（StoreKit 2 不支持自定义字符串，忽略该参数）
    func startPay(productId: String, orderId: String) {
        self.currPaymentType = .purchase
        applePayLog.add(type: .start, title: "开始购买", des: "发送购买请求")
        let token = UUID()
        self.currentOrderToken = token
        self.orderMap[token] = OrderRecord(orderId: orderId, createdAt: Date())
        Self.persistOrderMap(self.orderMap)
        self.purchaseTask = Task { [weak self] in
            await self?.fetchAndPurchase(productId: productId, token: token)
        }
    }
    
    /// 恢复购买
    func restore() {
        self.currPaymentType = .restore
        applePayLog.add(type: .start, title: "开始恢复", des: "开始请求恢复数据")
        self.restoreTask = Task { [weak self] in
            await self?.restoreEntitlements()
        }
    }
    
    /// 获取本地购买凭证
    func getLocalReceiptInfo() -> String? {
        let info = Self.receiptInfo()
        if let receiptStr = info.receiptStr {
            applePayLog.add(type: .end, title: "获取本地票据", des: "本地有票据")
            return receiptStr
        } else {
            applePayLog.add(type: .end, title: "获取本地票据", des: "本地无票据\(info.msg)")
            return nil
        }
    }
    
    func cancel() {
        applePayLog.add(type: .end, title: "applePayment", des: "外部调用取消")
        self.purchaseTask?.cancel()
        self.restoreTask?.cancel()
        self.purchaseTask = nil
        self.restoreTask = nil
        self.clearData()
    }
    
    private func clearData() {
        self.currPaymentType = nil
    }
    
    //MARK: ---------------订单持久化-----------------
    
    /// 持久化存储 key
    private nonisolated static let orderMapKey = "SWToolKit.ApplePay.orderMap"

    /// 订单映射过期时间（Ask to Buy 无苹果超时上限，超时后清理避免堆积）
    private nonisolated static let maxOrderAge: TimeInterval = 30 * 24 * 3600

    /// 从本地恢复订单映射（token → orderId），并清理过期条目
    private nonisolated static func loadOrderMap() -> [UUID: OrderRecord] {
        guard let raw = UserDefaults.standard.dictionary(forKey: orderMapKey) as? [String: String] else { return [:] }
        let deadline = Date().addingTimeInterval(-maxOrderAge)
        var map: [UUID: OrderRecord] = [:]
        for (key, value) in raw {
            guard let uuid = UUID(uuidString: key) else { continue }
            let record: OrderRecord?
            if let data = value.data(using: .utf8) {
                record = try? JSONDecoder().decode(OrderRecord.self, from: data)
            } else {
                record = nil
            }
            if let record {
                if record.createdAt >= deadline {
                    map[uuid] = record
                }
            } else {
                // 兼容旧格式（value 直接为 orderId 字符串）
                let legacy = OrderRecord(orderId: value, createdAt: Date())
                if legacy.createdAt >= deadline {
                    map[uuid] = legacy
                }
            }
        }
        return map
    }

    /// 保存订单映射到本地，并清理过期条目
    private nonisolated static func persistOrderMap(_ map: [UUID: OrderRecord]) {
        let deadline = Date().addingTimeInterval(-maxOrderAge)
        var raw: [String: String] = [:]
        for (key, value) in map where value.createdAt >= deadline {
            if let data = try? JSONEncoder().encode(value),
               let json = String(data: data, encoding: .utf8) {
                raw[key.uuidString] = json
            }
        }
        UserDefaults.standard.set(raw, forKey: orderMapKey)
    }
    
    //MARK: ---------------购买-----------------
    
    /// 获取商品信息并发起购买
    private func fetchAndPurchase(productId: String, token: UUID) async {
        do {
            let products = try await Product.products(for: [productId])
            guard let product = products.first else {
                applePayLog.add(type: .product, title: "产品回调", des: "苹果商品内购产品Id与用户申请购买Id不匹配")
                self.failResultHandle(type: .noOrder, msg: "没有找到指定商品", token: token)
                return
            }
            try await self.purchase(product, token: token)
        } catch {
            guard !Task.isCancelled else { return }
            applePayLog.add(type: .product, title: "产品回调", des: "获取产品信息失败\(error.localizedDescription)")
            self.failResultHandle(type: .noOrder, msg: error.localizedDescription, token: token)
        }
    }
    
    /// 发起购买
    private func purchase(_ product: Product, token: UUID) async throws {
        let result = try await product.purchase(options: [.appAccountToken(token)])
        switch result {
        case .success(let verificationResult):
            do {
                /// 校验交易凭证
                let transaction = try verificationResult.payloadValue
                await self.deliverVerifiedTransaction(transaction)
            } catch {
                self.failResultHandle(type: .buyFail, msg: error.localizedDescription, token: token)
            }
        case .userCancelled:
            /// 用户取消了购买
            self.failResultHandle(type: .buyCancel, msg: "交易已取消", token: token)
        case .pending:
            /// 交易挂起，可能需要家长同意等（保留 orderMap 条目，晚到批准仍可发货）
            applePayLog.add(type: .statusChange, title: "购买事物变更", des: "交易延期")
            self.currPaymentType = nil
            self.callbackMain { $0.applePayServicePending() }
        @unknown default:
            self.failResultHandle(type: .other, msg: "未知问题", token: token)
        }
    }
    
    //MARK: ---------------恢复购买-----------------
    
    /// 恢复购买
    private func restoreEntitlements() async {
        var hasEntitlement = false
        /// 遍历用户当前的所有权益（已购买且未退款的有效非消耗型商品和订阅）
        for await result in Transaction.currentEntitlements {
            if let transaction = try? result.payloadValue {
                hasEntitlement = true
                await transaction.finish()
            }
        }
        if hasEntitlement {
            let info = Self.receiptInfo()
            if let receiptStr = info.receiptStr {
                applePayLog.add(type: .end, title: "恢复购买", des: "本地有票据")
                self.callbackMain { delegate in
                    delegate.applePayServiceRestore(receipt: receiptStr)
                }
                self.clearData()
            } else {
                self.failResultHandle(type: .restoreFail, msg: info.msg)
            }
        } else {
            /// 没有可恢复的购买项
            self.failResultHandle(type: .restoreFail, msg: "没有可恢复的购买项")
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
    
    /// 处理已验证事务：能关联到本 App 发起的订单则发货，否则仅结束
    private func deliverVerifiedTransaction(_ transaction: StoreKit.Transaction) async {
        /// 自动续费（续订，非首次购买）：不发货，仅结束
        if transaction.productType == .autoRenewable && transaction.originalID != transaction.id {
            applePayLog.add(type: .statusChange, title: "购买事物变更", des: "自动续费续订，不发货")
            await transaction.finish()
            return
        }
        /// 关联订单：优先 appAccountToken，回退到当前购买 token
        let token: UUID
        if let appToken = transaction.appAccountToken {
            token = appToken
        } else if let current = self.currentOrderToken {
            token = current
        } else {
            await transaction.finish()
            return
        }
        guard let record = self.orderMap.removeValue(forKey: token) else {
            await transaction.finish()
            return
        }
        if self.currentOrderToken == token {
            self.currentOrderToken = nil
        }
        Self.persistOrderMap(self.orderMap)
        /// 撤销/退款/家庭共享移除：不发货，按取消处理
        if transaction.revocationDate != nil {
            applePayLog.add(type: .statusChange, title: "购买事物变更", des: "交易被撤销")
            self.failResultHandle(type: .buyCancel, msg: "交易被撤销")
            await transaction.finish()
            return
        }
        let info = Self.receiptInfo()
        if let receiptStr = info.receiptStr {
            applePayLog.add(type: .end, title: "购买新产品", des: "本地有票据")
            self.callbackMain { $0.applePayServiceSuccess(receipt: receiptStr, orderId: record.orderId) }
        } else {
            self.callbackMain { $0.applePayServiceFail(type: .buyFail, message: info.msg) }
        }
        self.clearData()
        await transaction.finish()
    }
    
    //MARK: ---------------结果处理-----------------
    
    /// 结果处理并将支付结果返回给调用端
    private func failResultHandle(type: ApplePayManager.ResultFailType, msg: String, token: UUID? = nil) {
        applePayLog.add(type: .end, title: (currPaymentType?.des() ?? "未知") + "失败", des: type.des() + ":\(msg)")
        if let token {
            self.orderMap.removeValue(forKey: token)
            if self.currentOrderToken == token {
                self.currentOrderToken = nil
            }
            Self.persistOrderMap(self.orderMap)
        }
        self.clearData()
        self.callbackMain { delegate in
            delegate.applePayServiceFail(type: type, message: msg)
        }
    }
    
    /// 保证代理回调在主线程执行（类已 @MainActor，直接回调）
    private func callbackMain(_ block: @escaping (ApplePayServiceDelegate) -> Void) {
        guard let delegate = self.serviceDelegate else { return }
        block(delegate)
    }
    
    /// 获取凭证
    private static func receiptInfo() -> (msg: String, receiptStr: String?) {
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
    
}


//MARK: ---------------SKPaymentTransactionObserver-----------------
/// 仅用于处理 AppStore 促销点击购买
extension ApplyPaymentNew: @preconcurrency SKPaymentTransactionObserver {
    
    /// 当用户从应用商店发起应用内购买操作时发送此消息
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return serviceDelegate?.applePayServiceShouldAddStorePayment() ?? false
    }
    
    /// 处理经由旧队列回调的交易
    /// StoreKit 2 的主要逻辑在 Transaction.updates 中处理，这里仅结束交易，避免卡住交易队列
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for trans in transactions {
            switch trans.transactionState {
            case .purchased, .failed, .restored:
                applePayLog.add(type: .statusChange, title: "购买事物变更", des: "旧队列交易结束(\(trans.transactionState.rawValue))")
                SKPaymentQueue.default().finishTransaction(trans)
            default:
                break
            }
        }
    }
    
}
