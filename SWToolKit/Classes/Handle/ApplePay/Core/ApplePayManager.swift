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
    
    /// 支付失败结果（带订单号/商品号，便于宿主对账，迟到失败也能知道是哪一单）
    /// 恢复失败、商品请求失败、促销交易等场景 orderId/productId 可能为空。
    ///
    /// 必须声明成协议要求：协议扩展里的方法通过协议存在体调用时是静态派发，
    /// 宿主的实现不会被调用（只会走下面的默认实现）。
    func applePayResult(pay: ApplePayManager, type: ApplePayManager.ResultFailType,
                        errorMsg: String, orderId: String?, productId: String?)
    
}


public extension ApplePayManagerDelegate {
    
    /// 老宿主无需实现带订单号的重载，默认转发到旧方法
    func applePayResult(pay: ApplePayManager, type: ApplePayManager.ResultFailType,
                        errorMsg: String, orderId: String?, productId: String?) {
        applePayResult(pay: pay, type: type, errorMsg: errorMsg)
    }
    
}


/// 内购统一入口。
/// 只负责：会话状态、超时、委托路由、票据读取/刷新的排队；
/// 具体支付流程（监听、购买、恢复）由 `ApplePayEngine` 的实现负责。
///
/// 线程模型：
/// - `pay` / `finish` 必须在主线程调用（StoreKit 2 的 `Product.purchase` 本身就要求 MainActor）；
/// - `restore` / `getLocalReceiptInfo` / `refreshLocalReceiptInfo` 可以在任意线程调用：
///   必要的状态切换投递到主线程，耗时写盘放到后台，不阻塞调用线程；
/// - 会话、等待者、模式等可变状态统一由 `stateLock` 保护。
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
    
    /// 跨线程状态锁。
    /// 用递归锁：引擎存在同步回调（例如商品信息请求失败会立刻回调 engineFail），
    /// 同线程重入本类的加锁方法，普通 NSLock 会自死锁。
    private let stateLock = NSRecursiveLock()

    @inline(__always)
    private func withStateLock<T>(_ body: () -> T) -> T {
        self.stateLock.lock()
        defer { self.stateLock.unlock() }
        return body()
    }
    
    /// 刷新本地数据
    private var receiptRefresh: ReceiptRefreshService?
    /// 刷新进行中排队的凭证回调
    private var receiptWaiters: [(String?) -> Void] = []
    /// 刷新进行中排队的刷新结果回调
    private var refreshWaiters: [(Bool) -> Void] = []
    /// 内购引擎（根据 engineMode 选择 StoreKit 1 或 StoreKit 2）
    /// 首次使用时创建一次并持续复用，允许宿主在首次使用前设置 engineMode
    private var engineStorage: ApplePayEngine?
    /// 促销购买入口（两条链路共用，只负责 shouldAddStorePayment）
    private var promotedPurchaseStorage: PromotedPurchaseObserver?

    fileprivate override init() {
        super.init()
    }
 
    /// 当前支付/恢复会话（nil = 空闲；超时即释放，购买/恢复均可重新发起）
    private var currentSession: PaymentSession?
    /// 超时定时器
    private var paymentTimer: Timer?
    /// 恢复购买是否仍在苹果侧等待回调
    /// （会话超时释放锁后仍为 true，用于「恢复不并发」）
    private var restoreInFlight = false
   
    /// 支付代理（只由 initData 内部赋值）
    public private(set) weak var delegate: ApplePayManagerDelegate?
    
    /// 超时时间（读写可在任意线程）
    private var _timeoutInterval: TimeInterval = 150.0
    public var timeoutInterval: TimeInterval {
        get { self.withStateLock { self._timeoutInterval } }
        set { self.withStateLock { self._timeoutInterval = newValue } }
    }
    
    /// 购买/恢复引擎实现
    /// 默认 .legacy；必须在首次使用（initData / pay / restore）之前设置，
    /// 引擎创建后再修改不会重建，需下次启动生效。
    fileprivate var engineMode: ImplementationMode = .legacy
    /// 本地票据刷新实现
    /// 默认旧实现（SKReceiptRefreshRequest），与引擎默认值保持一致。
    /// 修改后下一次刷新生效，正在进行的刷新不会被打断。
    fileprivate var receiptRefreshMode: ImplementationMode = .legacy

    /// 内购引擎（只在主线程创建与访问）
    @MainActor
    private var engine: ApplePayEngine {
        if let engine = self.engineStorage {
            return engine
        }
        let mode = self.withStateLock { self.engineMode }
        let engine = ApplePayEngineFactory.makeEngine(mode: mode)
        engine.engineDelegate = self
        self.engineStorage = engine
        return engine
    }

    /// 促销购买入口（只在主线程创建与访问）
    @MainActor
    private var promotedPurchase: PromotedPurchaseObserver {
        if let observer = self.promotedPurchaseStorage {
            return observer
        }
        let observer = PromotedPurchaseObserver()
        observer.manager = self
        self.promotedPurchaseStorage = observer
        return observer
    }

    /// 初始化内购配置
    /// 建议在 App 启动、首次 pay / restore / 获取票据之前调用。
    /// - Parameters:
    ///   - engineMode: 购买/恢复引擎实现（默认 .legacy）
    ///   - receiptRefreshMode: 票据刷新实现（默认 .legacy）
    ///   - delegate: 支付结果代理，默认 nil
    public func initData(engineMode: ImplementationMode = .legacy,
                         receiptRefreshMode: ImplementationMode = .legacy,
                         delegate: ApplePayManagerDelegate? = nil) {
        /// 先写模式再写 delegate：delegate 赋值后 startHandle 会创建引擎，
        /// 引擎创建后修改 engineMode 不会重建，需下次启动生效
        self.withStateLock {
            self.engineMode = engineMode
            self.receiptRefreshMode = receiptRefreshMode
            self.delegate = delegate
        }
        /// 引擎与促销监听只能在主线程初始化
        Task { @MainActor [weak self] in
            self?.startHandle()
        }
    }


    ///开始支付
    /// - Note: 必须在主线程调用（StoreKit 2 购买本身要求 MainActor）
    @MainActor
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
        let busyType: ApplePayManager.StartFailType? = self.withStateLock {
            guard let session = self.currentSession else { return nil }
            return (session.type == .restore) ? .restoring : .purchasing
        }
        if let busyType {
            applePayLog.add(type: .start, title: "开始购买失败", des: "当前正在进行" + busyType.des())
            return busyType
        }
        let session: PaymentSession = self.withStateLock {
            self.resetSession()
            let session = PaymentSession(id: UUID(), type: .purchase, orderId: orderId, productId: productId)
            self.currentSession = session
            return session
        }
        applePayLog.add(type: .start, title: "开始购买", des: "流程Id:\(session.id.uuidString) 订单:\(orderId) 商品:\(productId)")
        self.requestProduct(pId: productId, orderId: orderId, sessionId: session.id)
        return nil
    }
    
    ///恢复购买
    /// - Note: 可在任意线程调用；会话切换投递到主线程执行，不阻塞调用线程
    public func restore() -> ApplePayManager.StartFailType? {
        var failType: ApplePayManager.StartFailType?
        var session: PaymentSession?
        self.withStateLock {
            if let current = self.currentSession {
                failType = (current.type == .restore) ? .restoring : .purchasing
                return
            }
            /// 上一次恢复超时已释放会话锁，但苹果回调还没回来：恢复不并发
            if self.restoreInFlight {
                failType = .restoring
                return
            }
            let newSession = PaymentSession(id: UUID(), type: .restore, orderId: nil, productId: nil)
            self.currentSession = newSession
            self.restoreInFlight = true
            session = newSession
        }
        if let failType {
            applePayLog.add(type: .start, title: "开始恢复失败", des: "当前正在进行" + failType.des())
            return failType
        }
        guard let session else { return nil }
        applePayLog.add(type: .start, title: "开始恢复", des: "流程Id:\(session.id.uuidString)")
        /// 超时定时器与引擎都只能在主线程操作
        Task { @MainActor [weak self] in
            guard let self else { return }
            /// 投递期间被 finish / 新流程清理掉就放弃，并解除「恢复不并发」
            let stillCurrent = self.withStateLock { () -> Bool in
                if self.currentSession?.id == session.id { return true }
                /// 只有当前没有新会话时才解除，避免旧任务清掉新恢复的标记
                if self.currentSession == nil {
                    self.restoreInFlight = false
                }
                return false
            }
            guard stillCurrent else { return }
            self.startHandle()
            self.startRestore(sessionId: session.id)
        }
        return nil
    }
    
    /// 清除多余数据
    /// - Note: 必须在主线程调用（需要中止引擎任务）
    @MainActor
    public func finish() {
        self.withStateLock {
            self.resetSession()
            self.restoreInFlight = false
        }
        /// 显式中止：取消引擎里仍在等待的任务
        /// 注意：引擎从未使用过时这里会顺带创建一次（两个引擎的 init 都不注册监听，只有 start() 才注册）
        self.engine.cancel()
    }

    /// 获取本地购买凭证
    /// - Note: 可在任意线程调用；回调统一在主线程触发
    public func getLocalReceiptInfo(back: ((String?) -> Void)?) {
        var shouldStart = false
        self.withStateLock {
            if let back {
                self.receiptWaiters.append(back)
            }
            /// 已有刷新在进行，等它结束时统一回调，避免后到的调用方永远等不到结果
            shouldStart = (self.receiptRefresh == nil)
        }
        guard shouldStart else { return }
        Task { @MainActor [weak self] in
            self?.startReceiptRefresh()
        }
    }

    /// 仅刷新本地票据
    /// - Note: 可在任意线程调用；回调统一在主线程触发
    public func refreshLocalReceiptInfo(back: ((Bool) -> Void)?) {
        var shouldStart = false
        self.withStateLock {
            if let back {
                self.refreshWaiters.append(back)
            }
            shouldStart = (self.receiptRefresh == nil)
        }
        guard shouldStart else { return }
        Task { @MainActor [weak self] in
            self?.startReceiptRefresh()
        }
    }
    
    /// 开始刷新本地票据，结束后统一回调所有等待者
    /// - Note: 只在主线程调用（`ReceiptRefreshService` 内部用 Timer 做超时）
    @MainActor
    private func startReceiptRefresh() {
        /// 并发调用可能重复投递，这里在主线程再确认一次
        let alreadyRefreshing = self.withStateLock { self.receiptRefresh != nil }
        guard !alreadyRefreshing else { return }
        let mode = self.withStateLock { self.receiptRefreshMode }
        applePayLog.add(type: .start, title: "本地票据", des: "开始(\(mode.rawValue))")
        let service = ReceiptRefreshFactory.make(mode: mode)
        self.withStateLock {
            self.receiptRefresh = service
        }
        service.refreshLocalReceiptInfo { [weak self] error in
            guard let self else { return }
            /// 回调时已在主线程；票据读取耗时在亚毫秒级，直接同步读取即可
            let info = AppReceipt.readAndLog()
            self.finishReceiptRefresh(error: error, info: info)
        }
    }

    /// 刷新结束：先取走等待者，再在主线程回调
    private func finishReceiptRefresh(error: Error?, info: (msg: String, receiptStr: String?)) {
        var receiptWaiters: [(String?) -> Void] = []
        var refreshWaiters: [(Bool) -> Void] = []
        self.withStateLock {
            self.receiptRefresh = nil
            receiptWaiters = self.receiptWaiters
            refreshWaiters = self.refreshWaiters
            self.receiptWaiters.removeAll()
            self.refreshWaiters.removeAll()
        }
        applePayLog.add(type: .start, title: "本地票据", des: "刷新本地票据(\((error as? NSError)?.domain ?? "成功"))")
        let success = (error == nil)
        receiptWaiters.forEach { $0(info.receiptStr) }
        refreshWaiters.forEach { $0(success) }
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
    @MainActor
    private func startHandle() {
        self.engine.start()
        self.promotedPurchase.start()
    }

    /// 是否接受 App Store 促销购买（由 PromotedPurchaseObserver 调用）
    /// - Note: 持有的是 delegate 的强引用快照，调用宿主实现时不持锁，避免宿主重入死锁
    func shouldAcceptPromotedPurchase() -> Bool {
        let delegate = self.withStateLock { self.delegate }
        return delegate?.shouldAddStorePayment() ?? false
    }
    
    /// 释放会话锁（超时/成功/失败/开始新流程共用）
    /// 注意：这里不取消引擎，超时后苹果侧流程继续走完，迟到结果照常上报
    /// - Note: 只在主线程调用（会 invalidate Timer）
    private func resetSession() {
        self.paymentTimer?.invalidate()
        self.paymentTimer = nil
        self.currentSession = nil
        applePayLog.add(type: .clear, title: "清理数据", des: "释放支付会话（不中止苹果流程）")
    }
    
    /// 超时：只释放会话锁并上报，不打断苹果流程
    @objc private func paymentTimeOut() {
        var session: PaymentSession?
        var delegate: ApplePayManagerDelegate?
        self.withStateLock {
            session = self.currentSession
            delegate = self.delegate
            self.resetSession()
        }
        applePayLog.add(type: .end, title: session?.type.des() ?? "未知",
                        des: "超时未处理 流程Id:\(session?.id.uuidString ?? "-")")
        delegate?.applePayResult(pay: self, type: .timeout, errorMsg: "超时未处理",
                                 orderId: session?.orderId, productId: session?.productId)
    }
    
    //MARK: ---------------开始支付-----------------
    
    /// 开始恢复购买
    @MainActor
    private func startRestore(sessionId: UUID) {
        self.paymentTimer?.invalidate()
        self.paymentTimer = Timer.scheduledTimer(timeInterval: self.timeoutInterval, target: self, selector: #selector(paymentTimeOut), userInfo: nil, repeats: false)
        self.engine.restore(sessionId: sessionId)
    }

    ///获得购买的产品信息
    @MainActor
    private func requestProduct(pId: String, orderId: String, sessionId: UUID) {
        self.paymentTimer?.invalidate()
        self.paymentTimer = Timer.scheduledTimer(timeInterval: self.timeoutInterval, target: self, selector: #selector(paymentTimeOut), userInfo: nil, repeats: false)
        applePayLog.add(type: .start, title: "开始获得本地票据，若没有会从网络上请求", des: "流程Id:\(sessionId.uuidString)")
        self.engine.startPay(productId: pId, orderId: orderId, sessionId: sessionId)
    }
    
}


extension ApplePayManager: ApplePayEngineDelegate {
    
    /// 回调是否属于当前会话；nil 一律视为 App 外交易，只上报、不清会话
    /// - Note: 调用方需已持有 stateLock
    private func isCurrentSession(_ sessionId: UUID?) -> Bool {
        return sessionId != nil && sessionId == self.currentSession?.id
    }
    
    func engineSuccess(_ engine: ApplePayEngine, sessionId: UUID?, productId: String, orderId: String?, receipt: String) -> Bool {
        var isCurrent = false
        var expectedProductId: String?
        self.withStateLock {
            let session = self.currentSession
            isCurrent = self.isCurrentSession(sessionId)
            /// 下单商品必须与回调商品一致；不一致时记录日志，并继续交付实际商品
            if isCurrent, productId != session?.productId {
                expectedProductId = session?.productId
            }
        }
        if isCurrent, let expectedProductId {
            applePayLog.add(type: .statusChange, title: "商品不匹配",
                            des: "继续交付实际商品 流程Id:\(sessionId?.uuidString ?? "-") 下单:\(expectedProductId) 回调:\(productId)")
        }
        applePayLog.add(type: .statusChange, title: "购买事物变更",
                        des: "交付商品(\(productId)) 流程Id:\(sessionId?.uuidString ?? "-") 订单:\(orderId ?? "-")")
        /// 先清会话再回调：上层常在回调里立即发起下一笔，清理晚于回调会被误判为"正在购买中"
        if isCurrent {
            self.withStateLock {
                self.resetSession()
            }
        }
        guard let delegate = self.withStateLock({ self.delegate }) else {
            /// 宿主代理为空无法投递：让引擎保留交易，等下次启动（unfinished/队列）重试
            applePayLog.add(type: .end, title: "投递失败",
                            des: "宿主代理为空，保留交易待重试 流程Id:\(sessionId?.uuidString ?? "-") 订单:\(orderId ?? "-")")
            return false
        }
        delegate.applePaySuccess(pay: self, orderId: orderId, encode: receipt)
        return true
    }
    
    func engineRestore(_ engine: ApplePayEngine, sessionId: UUID?, receipt: String) {
        var isCurrent = false
        self.withStateLock {
            self.restoreInFlight = false
            isCurrent = self.isCurrentSession(sessionId)
            if isCurrent {
                self.resetSession()
            }
        }
        applePayLog.add(type: .end, title: "恢复购买", des: "恢复成功 流程Id:\(sessionId?.uuidString ?? "-")")
        self.withStateLock({ self.delegate })?.applePayRestore(pay: self, encode: receipt)
    }
    
    func engineFail(_ engine: ApplePayEngine, sessionId: UUID?, productId: String?, orderId: String?, type: ResultFailType, message: String) {
        var isCurrent = false
        var sessionType: PaymentType?
        var expectedProductId: String?
        self.withStateLock {
            let session = self.currentSession
            sessionType = session?.type
            isCurrent = self.isCurrentSession(sessionId)
            if isCurrent, let productId, let expected = session?.productId, productId != expected {
                expectedProductId = expected
            }
            /// 恢复流程的失败要解除「恢复不并发」
            if type == .restoreFail || type == .restoreCancel {
                self.restoreInFlight = false
            }
            /// 撤销通知仅记录，不清进行中的购买会话
            if isCurrent && type != .revoked {
                self.resetSession()
            }
        }
        if isCurrent, let expectedProductId {
            applePayLog.add(type: .statusChange, title: "商品不匹配",
                            des: "流程Id:\(sessionId?.uuidString ?? "-") 下单:\(expectedProductId) 回调:\(productId ?? "-")")
        }
        applePayLog.add(type: .end, title: sessionType?.des() ?? "未知",
                        des: "\(type.des()):\(message) 流程Id:\(sessionId?.uuidString ?? "-") 订单:\(orderId ?? "-")")
        self.withStateLock({ self.delegate })?.applePayResult(pay: self, type: type, errorMsg: message,
                                                             orderId: orderId, productId: productId)
    }

    func enginePending(_ engine: ApplePayEngine, sessionId: UUID?, productId: String?, orderId: String?) {
        var sessionType: PaymentType?
        self.withStateLock {
            sessionType = self.currentSession?.type
            if self.isCurrentSession(sessionId) {
                self.resetSession()
            }
        }
        applePayLog.add(type: .end, title: sessionType?.des() ?? "未知",
                        des: "交易挂起(等待批准) 流程Id:\(sessionId?.uuidString ?? "-") 订单:\(orderId ?? "-") 商品:\(productId ?? "-")")
        self.withStateLock({ self.delegate })?.applePayResult(pay: self, type: .pending, errorMsg: "等待批准",
                                                             orderId: orderId, productId: productId)
    }

}

private extension Array {
    /// 转 JSON 字符串（内部使用，原 Array+Extend 中的 toJson）
    func toJson(options opt: JSONSerialization.WritingOptions = []) -> String {
        guard JSONSerialization.isValidJSONObject(self) else {
            debugPrint("==SWToolKit==" + "无法解析出JSONString")
            return ""
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: opt)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            debugPrint("==SWToolKit==toJson error:", error)
            return ""
        }
    }
}
