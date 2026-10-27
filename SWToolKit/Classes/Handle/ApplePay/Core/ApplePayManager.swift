//
//  ApplePayManager.swift
//

import Foundation


public protocol ApplePayManagerDelegate: NSObject {
    
    /// 支付失败结果的代理
    func applePayResult(pay: ApplePayManager, type: ApplePayManager.ResultFailType, errorMsg: String)
    
    /// 支付成功的代理
    func applePaySuccess(pay: ApplePayManager, orderId: String?, encode: String)

    /// 恢复购买
    func applePayRestore(pay: ApplePayManager, encode: String)
    
    /// 检测是否可以从AppStore促销点击购买处理
    func shouldAddStorePayment() -> Bool
    
}


public extension ApplePayManagerDelegate {
    
    /// 支付失败结果（带订单号/商品号，便于宿主对账，迟到失败也能知道是哪一单）
    /// 恢复失败、商品请求失败、促销交易等场景 orderId/productId 可能为空。
    /// 老宿主无需实现，默认转发到旧方法。
    func applePayResult(pay: ApplePayManager, type: ApplePayManager.ResultFailType,
                        errorMsg: String, orderId: String?, productId: String?) {
        applePayResult(pay: pay, type: type, errorMsg: errorMsg)
    }
    
}


/// 内购统一入口。
/// 只负责：会话状态、超时、委托路由、票据读取/刷新的排队；
/// 具体支付流程（监听、购买、恢复）由 `ApplePayEngine` 的实现负责。
@MainActor
public class ApplePayManager: NSObject {

    /// 一次支付/恢复流程的会话（创建与销毁总是成对出现）
    private struct PaymentSession {
        /// 流程 Id：购买时写入 appAccountToken / applicationUsername，回调原样带回
        let id: UUID
        let type: PaymentType
        /// 业务订单号（恢复购买无订单号）
        let orderId: String?
        /// 商品 Id（恢复购买无商品）
        let productId: String?
    }
    
    public static let share = ApplePayManager()
    /// 刷新本地数据
    private var receiptRefresh: ReceiptRefreshService?
    /// 刷新进行中排队的凭证回调
    private var receiptWaiters: [(String?) -> Void] = []
    /// 刷新进行中排队的刷新结果回调
    private var refreshWaiters: [(Bool) -> Void] = []
    /// 内购引擎（根据系统版本选择 StoreKit 1 或 StoreKit 2）
    private let engine: ApplePayEngine
    /// 促销购买入口（两条链路共用，只负责 shouldAddStorePayment）
    private let promotedPurchase: PromotedPurchaseObserver

    fileprivate override init() {
        self.engine = ApplePayEngineFactory.makeEngine()
        self.promotedPurchase = PromotedPurchaseObserver()
        super.init()
        self.engine.engineDelegate = self
        self.promotedPurchase.manager = self
    }
 
    /// 当前支付/恢复会话（nil = 空闲；超时即释放，购买/恢复均可重新发起）
    private var currentSession: PaymentSession?
    /// 超时定时器
    private var paymentTimer: Timer?
    
   
    ///支付代理
    public weak var delegate: ApplePayManagerDelegate? {
        didSet {
            if delegate != nil {
                self.startHandle()
            }
        }
    }
    
    /// 超时时间
    public var timeoutInterval: TimeInterval = 150.0
    
    
    ///开始支付
    public func pay(productId: String) -> ApplePayManager.StartFailType? {
        return self.pay(productId: productId, orderId: productId)
    }

    ///开始支付
    public func pay(productId: String, orderId: String) -> ApplePayManager.StartFailType? {
        self.startHandle()
        guard self.engine.checkCanPayment() else {
            let type: ApplePayManager.StartFailType = .cannotPayments
            applePayLog.add(type: .start, title: "开始购买失败", des: type.des())
            return type
        }
        guard productId.count > 0 else {
            let type: ApplePayManager.StartFailType = .productIdNull
            applePayLog.add(type: .start, title: "开始购买失败", des: type.des())
            return type
        }
        /// 有会话说明正在购买或恢复中
        if let session = self.currentSession {
            let type: ApplePayManager.StartFailType = ((session.type == .restore) ? .restoring : .purchasing)
            applePayLog.add(type: .start, title: "开始购买失败", des: "当前正在进行" + type.des())
            return type
        }
        self.resetSession()
        let session = PaymentSession(id: UUID(), type: .purchase, orderId: orderId, productId: productId)
        self.currentSession = session
        applePayLog.add(type: .start, title: "开始购买", des: "流程Id:\(session.id.uuidString) 订单:\(orderId) 商品:\(productId)")
        self.requestProduct(pId: productId, orderId: orderId, sessionId: session.id)
        return nil
    }
    
    ///恢复购买
    public func restore() -> ApplePayManager.StartFailType? {
        self.startHandle()
        if let session = self.currentSession {
            let type: ApplePayManager.StartFailType = ((session.type == .restore) ? .restoring : .purchasing)
            applePayLog.add(type: .start, title: "开始恢复失败", des: "当前正在进行" + type.des())
            return type
        }
        /// 上一次恢复超时已释放会话锁，但苹果回调还没回来：恢复不并发
        if self.engine.isRestoreInFlight {
            let type: ApplePayManager.StartFailType = .restoring
            applePayLog.add(type: .start, title: "开始恢复失败", des: "上一次恢复仍在苹果侧处理中，" + type.des())
            return type
        }
        self.resetSession()
        let session = PaymentSession(id: UUID(), type: .restore, orderId: nil, productId: nil)
        self.currentSession = session
        applePayLog.add(type: .start, title: "开始恢复", des: "流程Id:\(session.id.uuidString)")
        self.startRestore(sessionId: session.id)
        return nil
    }
    
    /// 清除多余数据
    public func finish() {
        self.resetSession()
        /// 显式中止：取消引擎里仍在等待的任务
        self.engine.cancel()
    }

    /// 获取本地购买凭证
    public func getLocalReceiptInfo(back: ((String?) -> Void)?) {
        if let back {
            self.receiptWaiters.append(back)
        }
        /// 已有刷新在进行，等它结束时统一回调，避免后到的调用方永远等不到结果
        guard self.receiptRefresh == nil else { return }
        self.startReceiptRefresh()
    }

    /// 仅刷新本地票据
    public func refreshLocalReceiptInfo(back: ((Bool) -> Void)?) {
        if let back {
            self.refreshWaiters.append(back)
        }
        guard self.receiptRefresh == nil else { return }
        self.startReceiptRefresh()
    }
    
    /// 开始刷新本地票据，结束后统一回调所有等待者
    private func startReceiptRefresh() {
        applePayLog.add(type: .start, title: "本地票据", des: "开始")
        self.receiptRefresh = ReceiptRefreshService()
        self.receiptRefresh?.refreshLocalReceiptInfo { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                applePayLog.add(type: .start, title: "本地票据", des: "刷新本地票据(\((error as? NSError)?.domain ?? "成功"))")
                self.receiptRefresh = nil
                let info = AppReceipt.readAndLog()
                let success = (error == nil)
                let receiptWaiters = self.receiptWaiters
                let refreshWaiters = self.refreshWaiters
                self.receiptWaiters.removeAll()
                self.refreshWaiters.removeAll()
                receiptWaiters.forEach { $0(info.receiptStr) }
                refreshWaiters.forEach { $0(success) }
            }
        }
    }
    
    /// 刷新苹果内购的数据
    public func reloadProductInfo(ids: [String]) {
        applePayLog.add(type: .product, title: "刷新本地票据", des: "票据Id:\(ids.toJson())")
    }
    
    /// 日志
    public func logInfo() -> [String] {
        return applePayLog.getInfo()
    }
    
}




extension ApplePayManager {

    /// 启动引擎与促销购买监听（重复调用无副作用）
    private func startHandle() {
        self.engine.start()
        self.promotedPurchase.start()
    }

    /// 是否接受 App Store 促销购买（由 PromotedPurchaseObserver 调用）
    func shouldAcceptPromotedPurchase() -> Bool {
        return self.delegate?.shouldAddStorePayment() ?? false
    }
    
    /// 释放会话锁（超时/成功/失败/开始新流程共用）
    /// 注意：这里不取消引擎，超时后苹果侧流程继续走完，迟到结果照常上报
    private func resetSession() {
        self.paymentTimer?.invalidate()
        self.paymentTimer = nil
        self.currentSession = nil
        applePayLog.add(type: .clear, title: "清理数据", des: "释放支付会话（不中止苹果流程）")
    }
    
    /// 超时：只释放会话锁并上报，不打断苹果流程
    @objc private func paymentTimeOut() {
        let session = self.currentSession
        self.resetSession()
        applePayLog.add(type: .end, title: session?.type.des() ?? "未知",
                        des: "超时未处理 流程Id:\(session?.id.uuidString ?? "-")")
        self.delegate?.applePayResult(pay: self, type: .timeout, errorMsg: "超时未处理",
                                      orderId: session?.orderId, productId: session?.productId)
    }
    
    //MARK: ---------------开始支付-----------------
    
    /// 开始恢复购买
    private func startRestore(sessionId: UUID) {
        self.paymentTimer?.invalidate()
        self.paymentTimer = Timer.scheduledTimer(timeInterval: timeoutInterval, target: self, selector: #selector(paymentTimeOut), userInfo: nil, repeats: false)
        self.engine.restore(sessionId: sessionId)
    }

    ///获得购买的产品信息
    private func requestProduct(pId: String, orderId: String, sessionId: UUID) {
        self.paymentTimer?.invalidate()
        self.paymentTimer = Timer.scheduledTimer(timeInterval: timeoutInterval, target: self, selector: #selector(paymentTimeOut), userInfo: nil, repeats: false)
        applePayLog.add(type: .start, title: "开始获得本地票据，若没有会从网络上请求", des: "流程Id:\(sessionId.uuidString)")
        self.engine.startPay(productId: pId, orderId: orderId, sessionId: sessionId)
    }
    
}


extension ApplePayManager: ApplePayEngineDelegate {
    
    /// 回调是否属于当前会话；nil 一律视为 App 外交易，只上报、不清会话
    private func isCurrentSession(_ sessionId: UUID?) -> Bool {
        return sessionId != nil && sessionId == self.currentSession?.id
    }
    
    func engineSuccess(_ engine: ApplePayEngine, sessionId: UUID?, productId: String, orderId: String?, receipt: String) -> Bool {
        let session = self.currentSession
        let isCurrent = self.isCurrentSession(sessionId)
        /// 下单商品必须与回调商品一致；不一致时记录日志，并继续交付实际商品
        if isCurrent, productId != session?.productId {
            applePayLog.add(type: .statusChange, title: "商品不匹配",
                            des: "继续交付实际商品 流程Id:\(sessionId?.uuidString ?? "-") 下单:\(session?.productId ?? "-") 回调:\(productId)")
        }
        applePayLog.add(type: .statusChange, title: "购买事物变更",
                        des: "交付商品(\(productId)) 流程Id:\(sessionId?.uuidString ?? "-") 订单:\(orderId ?? "-")")
        /// 先清会话再回调：上层常在回调里立即发起下一笔，清理晚于回调会被误判为"正在购买中"
        if isCurrent {
            self.resetSession()
        }
        guard let delegate = self.delegate else {
            /// 宿主代理为空无法投递：让引擎保留交易，等下次启动（unfinished/队列）重试
            applePayLog.add(type: .end, title: "投递失败",
                            des: "宿主代理为空，保留交易待重试 流程Id:\(sessionId?.uuidString ?? "-") 订单:\(orderId ?? "-")")
            return false
        }
        delegate.applePaySuccess(pay: self, orderId: orderId, encode: receipt)
        return true
    }
    
    func engineRestore(_ engine: ApplePayEngine, sessionId: UUID?, receipt: String) {
        applePayLog.add(type: .end, title: "恢复购买", des: "恢复成功 流程Id:\(sessionId?.uuidString ?? "-")")
        if self.isCurrentSession(sessionId) {
            self.resetSession()
        }
        self.delegate?.applePayRestore(pay: self, encode: receipt)
    }
    
    func engineFail(_ engine: ApplePayEngine, sessionId: UUID?, productId: String?, orderId: String?, type: ResultFailType, message: String) {
        let session = self.currentSession
        let isCurrent = self.isCurrentSession(sessionId)
        if isCurrent, let productId, let expected = session?.productId, productId != expected {
            applePayLog.add(type: .statusChange, title: "商品不匹配",
                            des: "流程Id:\(sessionId?.uuidString ?? "-") 下单:\(expected) 回调:\(productId)")
        }
        applePayLog.add(type: .end, title: session?.type.des() ?? "未知",
                        des: "\(type.des()):\(message) 流程Id:\(sessionId?.uuidString ?? "-") 订单:\(orderId ?? "-")")
        /// 撤销通知仅记录，不清进行中的购买会话
        if isCurrent && type != .revoked {
            self.resetSession()
        }
        self.delegate?.applePayResult(pay: self, type: type, errorMsg: message,
                                      orderId: orderId, productId: productId)
    }

    func enginePending(_ engine: ApplePayEngine, sessionId: UUID?, productId: String?, orderId: String?) {
        applePayLog.add(type: .end, title: self.currentSession?.type.des() ?? "未知",
                        des: "交易挂起(等待批准) 流程Id:\(sessionId?.uuidString ?? "-") 订单:\(orderId ?? "-") 商品:\(productId ?? "-")")
        if self.isCurrentSession(sessionId) {
            self.resetSession()
        }
        self.delegate?.applePayResult(pay: self, type: .pending, errorMsg: "等待批准",
                                      orderId: orderId, productId: productId)
    }

}
