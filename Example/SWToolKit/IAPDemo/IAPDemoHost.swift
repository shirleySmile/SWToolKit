//
//  IAPDemoHost.swift
//  SWToolKit_Example
//
//  从对外项目 MW_PaymentManager 抽出来的宿主侧流程：
//  单飞状态机、订单号对账、后台校验（mock）、finish 时机、代理回调。
//  只用于 Example，不参与 pod 发布。
//

import Foundation
import StoreKit
import SWToolKit


@MainActor
final class IAPDemoHost: NSObject {

    static let shared = IAPDemoHost()

    /// 对应 MW_OrderStatus
    enum State: String {
        case none = "空闲"
        case userBuy = "购买中"
        case userRestore = "恢复购买中"
        case unfinishedOrder = "启动静默恢复"
    }

    /// 模拟后台校验的行为
    enum MockMode: Int, CaseIterable {
        case success
        case failure
        case delayedSuccess
        case delayedFailure
        case never

        var title: String {
            switch self {
            case .success:        return "成功"
            case .failure:        return "失败"
            case .delayedSuccess: return "延迟成功"
            case .delayedFailure: return "延迟失败"
            case .never:          return "永不返回"
            }
        }

        var delay: TimeInterval {
            switch self {
            case .delayedSuccess, .delayedFailure: return 5
            default: return 0
            }
        }
    }

    private(set) var state: State = .none
    /// 当前流程的订单（对应 MW 的 currOrderInfo）
    private(set) var currentOrder: IAPDemoOrder?
    /// 对应 MW 的 reqHandling：后台校验中，忽略重复成功回调
    private(set) var isVerifying = false

    var mockMode: MockMode = .success
    /// shouldAddStorePayment 的返回值
    var allowPromotedPurchase = true

    let orderStore = IAPDemoOrderStore()

    private let promoSimulator = IAPDemoPromoSimulator()

    private override init() {
        super.init()
    }

    // MARK: - 配置

    var delegateEnabled: Bool {
        get {
            if let value = UserDefaults.standard.object(forKey: IAPDemoConfig.delegateEnabledKey) as? Bool {
                return value
            }
            return true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: IAPDemoConfig.delegateEnabledKey)
        }
    }

    var isDelegateConnected: Bool {
        return ApplePayManager.share.delegate === self
    }

    func applyDelegateSetting() {
        if self.delegateEnabled {
            ApplePayManager.share.delegate = self
            self.log("已挂载 delegate（会启动苹果回调监听）")
        } else {
            ApplePayManager.share.delegate = nil
            self.log("已断开 delegate（发货时无法投递，交易会被保留）")
        }
    }

    func setTimeout(_ seconds: Double) {
        let value = max(1, seconds)
        ApplePayManager.share.timeoutInterval = value
        self.log("超时阈值设为 \(Int(value)) 秒")
    }

    // MARK: - 购买 / 恢复

    func buy(productId: String, orderId: String) {
        self.log("点击购买 商品:\(productId) 订单:\(orderId)")
        guard self.checkCanPayment() else { return }
        self.state = .userBuy

        if let fail = ApplePayManager.share.pay(productId: productId, orderId: orderId) {
            self.log("发起支付被拒绝：\(self.startFailText(fail))")
            self.state = .none
            return
        }

        self.currentOrder = IAPDemoOrder(orderId: orderId, productId: productId, createdAt: self.now())
        self.log("已发起支付，等待苹果回调（超时 \(Int(ApplePayManager.share.timeoutInterval)) 秒）")
    }

    func restore() {
        self.log("点击恢复购买")
        guard self.checkCanPayment() else { return }
        self.state = .userRestore

        if let fail = ApplePayManager.share.restore() {
            self.log("发起恢复被拒绝：\(self.startFailText(fail))")
            self.state = .none
            return
        }
        self.log("已发起恢复，等待苹果回调")
    }

    /// 对应 MW 的 launchCheck / mw_recoverUserVip
    func launchCheck() {
        let orders = self.orderStore.all()
        self.log("启动检测：本地未完成订单 \(orders.count) 条")
        guard !orders.isEmpty else { return }
        guard self.checkCanPayment() else { return }

        self.state = .unfinishedOrder
        if let fail = ApplePayManager.share.restore() {
            self.log("静默恢复被拒绝：\(self.startFailText(fail))")
            self.state = .none
        } else {
            self.log("已发起静默恢复")
        }
    }

    // MARK: - 票据 / 商品

    func refreshReceipt() {
        self.log("开始刷新本地票据")
        ApplePayManager.share.refreshLocalReceiptInfo { success in
            self.log("刷新票据结束 success=\(success)，当前：\(IAPDemoReceipt.status())")
        }
    }

    func readReceipt() {
        self.log("开始读取本地票据")
        ApplePayManager.share.getLocalReceiptInfo { receipt in
            if let receipt {
                self.log("读取票据结束：\(receipt.count) 字符")
            } else {
                self.log("读取票据结束：nil")
            }
        }
    }

    /// 校验 .storekit 本地配置是否生效
    func checkLocalProducts() {
        Task { [weak self] in
            do {
                let products = try await Product.products(for: IAPDemoConfig.productIds)
                let ids = products.map { $0.id }.sorted().joined(separator: ", ")
                self?.log("商品加载成功 \(products.count) 个：\(ids)")
            } catch {
                self?.log("商品加载失败：\(error.localizedDescription)")
            }
        }
    }

    // MARK: - 模拟促销

    /// SK1 才能用：直接入队一笔无 applicationUsername 的交易，
    /// 等价于 App Store 商品页的推广购买（外部交易）。
    func simulatePromotedPurchase(productId: String) {
        if #available(iOS 26.0, *) {
            self.log("iOS 26+ 已切到 StoreKit 2，SK1 入队不会被观察；请用 Xcode 的 Debug > StoreKit > Manage Transactions 模拟外部交易")
            return
        }
        self.promoSimulator.simulate(productId: productId)
    }

    /// 把 pod 内部日志打到面板。
    /// delegate 被断开时宿主收不到回调，只能靠这个确认交易是否被保留。
    func dumpPodLog() {
        let lines = ApplePayManager.share.logInfo()
        self.log("---- pod 日志开始（共 \(lines.count) 条，显示最近 80 条）----")
        lines.suffix(80).forEach { self.log("POD \($0)") }
        self.log("---- pod 日志结束 ----")
    }

    // MARK: - 内部

    private func checkCanPayment() -> Bool {
        switch self.state {
        case .userBuy:
            self.log("拦截：当前正在购买中")
            return false
        case .userRestore:
            self.log("拦截：当前正在恢复购买中")
            return false
        case .none, .unfinishedOrder:
            return true
        }
    }

    private func now() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }

    private func log(_ text: String) {
        IAPDemoLog.shared.add(text)
    }

    private func startFailText(_ type: ApplePayManager.StartFailType) -> String {
        switch type {
        case .productIdNull:  return "内购数据为空，请联系管理员"
        case .purchasing:     return "正在购买中，请稍后"
        case .restoring:      return "正在恢复购买中，请稍后"
        case .cannotPayments: return "当前设备不支持苹果内购"
        }
    }

    private func failTypeText(_ type: ApplePayManager.ResultFailType) -> String {
        switch type {
        case .buyCancel:     return "取消购买"
        case .buyFail:       return "购买失败"
        case .restoreCancel: return "取消恢复购买"
        case .restoreFail:   return "恢复购买失败"
        case .noOrder:       return "没有商品"
        case .timeout:       return "超时"
        case .other:         return "其他错误"
        case .pending:       return "交易挂起"
        case .revoked:       return "交易被撤销"
        }
    }

    /// 模拟 MW 的后台票据校验
    private func mockVerify(orderId: String, completion: @escaping @MainActor (Bool) -> Void) {
        self.log("开始后台校验（mock：\(self.mockMode.title)）")
        switch self.mockMode {
        case .success:
            completion(true)
        case .failure:
            completion(false)
        case .delayedSuccess:
            Task {
                try? await Task.sleep(nanoseconds: UInt64(MockMode.delayedSuccess.delay * 1_000_000_000))
                completion(true)
            }
        case .delayedFailure:
            Task {
                try? await Task.sleep(nanoseconds: UInt64(MockMode.delayedFailure.delay * 1_000_000_000))
                completion(false)
            }
        case .never:
            self.log("后台校验永不返回（用来观察超时后迟到回调）")
        }
    }

    /// 对应 MW 的 finishDataHandle：保存订单 + 释放 pod 会话
    private func finishDataHandle(deliveredOrderId: String? = nil, cancelEngine: Bool = true) {
        if let deliveredOrderId {
            if let order = self.currentOrder, order.orderId == deliveredOrderId {
                self.orderStore.save(order)
                self.log("保存订单：\(order.orderId)")
            } else if self.orderStore.all()[deliveredOrderId] == nil {
                self.orderStore.save(IAPDemoOrder(orderId: deliveredOrderId, productId: "-", createdAt: self.now()))
                self.log("补存迟到订单：\(deliveredOrderId)")
            }
        } else if let order = self.currentOrder {
            self.orderStore.save(order)
            self.log("保存订单：\(order.orderId)")
        }

        guard cancelEngine else {
            self.log("迟到回调：不调用 finish()，避免中断正在进行的新流程")
            return
        }

        self.currentOrder = nil
        self.isVerifying = false
        self.state = .none
        ApplePayManager.share.finish()
        self.log("宿主调用 finish()（此时引擎已经结束交易）")
    }

    private func handleFail(type: ApplePayManager.ResultFailType, errorMsg: String,
                            orderId: String?, productId: String?, source: String) {
        self.log("失败回调[\(source)] type=\(self.failTypeText(type)) msg=\(errorMsg) orderId=\(orderId ?? "nil") productId=\(productId ?? "nil")")

        switch type {
        case .buyCancel, .noOrder:
            self.currentOrder = nil
        case .pending:
            /// 挂起：pod 已释放项目级会话，但交易和订单映射保留，批准后仍按原 orderId 发货
            self.state = .none
            self.log("交易挂起：等待批准，订单映射保留")
            return
        case .revoked:
            /// 撤销只是通知，不动当前流程
            self.log("撤销通知：仅记录")
            return
        case .timeout:
            /// 超时只释放项目级锁；这里不调用 finish()，否则会打断苹果流程
            self.state = .none
            self.log("超时：项目级会话已释放，苹果流程继续；迟到回调会带回 orderId")
            return
        default:
            break
        }

        self.finishDataHandle()
    }

}


// MARK: - ApplePayManagerDelegate

extension IAPDemoHost: @preconcurrency ApplePayManagerDelegate {

    func applePayResult(pay: ApplePayManager, type: ApplePayManager.ResultFailType, errorMsg: String) {
        /// 老宿主（1.0.9）只实现这个方法
        self.handleFail(type: type, errorMsg: errorMsg,
                        orderId: self.currentOrder?.orderId,
                        productId: self.currentOrder?.productId,
                        source: "3 参回调")
    }

    func applePayResult(pay: ApplePayManager, type: ApplePayManager.ResultFailType, errorMsg: String,
                        orderId: String?, productId: String?) {
        /// 新宿主实现这个方法，才能拿到迟到失败对应的订单号
        self.handleFail(type: type, errorMsg: errorMsg,
                        orderId: orderId, productId: productId,
                        source: "4 参回调")
    }

    func applePaySuccess(pay: ApplePayManager, orderId: String?, encode: String) {
        self.log("成功回调 orderId=\(orderId ?? "nil") 票据=\(encode.count) 字符")

        guard !self.isVerifying else {
            self.log("后台校验中，忽略重复成功回调（对应 MW 的 reqHandling）")
            return
        }

        guard let orderId, !orderId.isEmpty else {
            self.log("无订单号的交易（促销/其他设备）：直接完成")
            /// 有流程进行中时不要调 finish()，否则会中断当前购买
            self.finishDataHandle(cancelEngine: self.currentOrder == nil)
            return
        }

        /// 是否属于「另一个流程结束时回来」的迟到回调
        let isLate = self.currentOrder.map { $0.orderId != orderId } ?? false
        if let current = self.currentOrder {
            if current.orderId == orderId {
                self.log("订单号核对一致：\(orderId)")
            } else {
                self.log("订单号不一致！下单=\(current.orderId) 回调=\(orderId)")
            }
        } else if self.orderStore.all()[orderId] != nil {
            self.log("迟到回调：订单号 \(orderId) 来自本地未完成订单")
        } else {
            self.log("迟到回调：订单号 \(orderId) 本地已无记录")
        }

        self.isVerifying = true
        self.mockVerify(orderId: orderId) { [weak self] success in
            guard let self else { return }
            self.isVerifying = false
            if success {
                self.log("后台校验成功")
                self.finishDataHandle(deliveredOrderId: orderId, cancelEngine: !isLate)
            } else {
                self.log("后台校验失败")
                self.finishDataHandle(cancelEngine: !isLate)
            }
        }
    }

    func applePayRestore(pay: ApplePayManager, encode: String) {
        self.log("恢复回调 票据=\(encode.count) 字符")
        self.finishDataHandle()
    }

    func shouldAddStorePayment() -> Bool {
        self.log("shouldAddStorePayment 被调用，返回 \(self.allowPromotedPurchase)")
        return self.allowPromotedPurchase
    }

}


// MARK: - SK1 促销模拟

/// 直接向 SKPaymentQueue 入队一笔没有 applicationUsername 的交易，
/// 模拟 App Store 商品页的推广购买。
final class IAPDemoPromoSimulator: NSObject, SKProductsRequestDelegate {

    private var request: SKProductsRequest?

    func simulate(productId: String) {
        IAPDemoLog.shared.add("模拟促销购买：请求商品 \(productId)")
        let request = SKProductsRequest(productIdentifiers: [productId])
        request.delegate = self
        self.request = request
        request.start()
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        defer { self.request = nil }
        guard let product = response.products.first else {
            IAPDemoLog.shared.add("模拟促销失败：商品不存在 invalid=\(response.invalidProductIdentifiers)")
            return
        }
        let payment = SKMutablePayment(product: product)
        payment.quantity = 1
        /// 关键：不设置 applicationUsername，等价于外部/促销交易
        payment.applicationUsername = nil
        SKPaymentQueue.default().add(payment)
        IAPDemoLog.shared.add("已入队一笔无 applicationUsername 的交易（模拟促销）")
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        self.request = nil
        IAPDemoLog.shared.add("模拟促销失败：\(error.localizedDescription)")
    }

}
