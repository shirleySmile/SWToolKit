//
//  ApplePayEngine.swift
//  Pods
//
//  内购引擎统一接口。
//  Core / Shared 不允许引用 Legacy / Current 里的具体类型；
//  只有装配工厂（ApplePayEngineFactory / ReceiptRefreshFactory）能看到两者。
//

import Foundation


/// 内购引擎：只描述“发起购买 / 恢复 / 监听”这些支付流程，
/// 票据读取与刷新由 Core + Shared 负责，引擎不参与。
@MainActor
protocol ApplePayEngine: AnyObject {

    /// 数据回调
    var engineDelegate: ApplePayEngineDelegate? { get set }

    /// 是否仍有恢复购买任务在苹果侧等待回调
    /// （会话超时释放锁后仍为 true，用于「恢复不并发」）
    var isRestoreInFlight: Bool { get }

    /// 检测是否可以使用内购
    func checkCanPayment() -> Bool

    /// 开始监听（注册观察者）
    func start()

    /// 开始支付（内部负责获取商品信息并发起购买）
    /// - Parameters:
    ///   - productId: 商品 Id
    ///   - orderId: 业务订单号
    ///   - sessionId: 支付流程 Id；SK2 写入 appAccountToken，SK1 写入 applicationUsername，
    ///                回调时由苹果原样带回，用于反查订单号
    func startPay(productId: String, orderId: String, sessionId: UUID)

    /// 恢复购买
    /// - Parameter sessionId: 本次恢复流程 Id，回调原样带回
    func restore(sessionId: UUID)

    /// 取消
    func cancel()
}


/// 内购引擎回调
@MainActor
protocol ApplePayEngineDelegate: AnyObject {

    /// 购买成功
    /// - Parameters:
    ///   - sessionId: 支付流程 Id；nil 表示 App 外交易（促销、其他设备、跨启动补偿），不可清当前会话
    ///   - productId: 苹果回调里的商品 Id（用于和下单时的商品 Id 校验）
    ///   - orderId: 关联订单号（无关联交易，例如 AppStore 促销购买、映射过期时为空）
    ///   - receipt: 本地购买凭证
    /// - Returns: 是否已投递给宿主。false 表示宿主代理为空，引擎必须保留交易
    ///   （不 finish、不删订单映射），等待下次启动重新投递
    func engineSuccess(_ engine: ApplePayEngine, sessionId: UUID?, productId: String, orderId: String?, receipt: String) -> Bool

    /// 恢复购买成功
    /// - Parameter sessionId: 发起恢复时的流程 Id（无法归属的回调为 nil）
    func engineRestore(_ engine: ApplePayEngine, sessionId: UUID?, receipt: String)

    /// 支付失败（恢复失败、商品请求失败等场景 productId/orderId 为空）
    func engineFail(_ engine: ApplePayEngine, sessionId: UUID?, productId: String?, orderId: String?, type: ApplePayManager.ResultFailType, message: String)

    /// 交易挂起（Ask to Buy 等），通知上层暂停超时
    func enginePending(_ engine: ApplePayEngine, sessionId: UUID?, productId: String?, orderId: String?)
}


/// 根据开关选择使用的内购引擎
@MainActor
enum ApplePayEngineFactory {

    /// - Parameter mode: 引擎实现模式，由 ApplePayManager.engineMode 传入
    static func makeEngine(mode:ApplePayManager.ImplementationMode) -> ApplePayEngine {
        /// 订单映射两条链路共用同一实例（进程内只会创建一个引擎）
        let store = PaymentOrderStore()
        switch mode {
        case .new:
            return SK2PaymentService(orderStore: store)
        case .legacy:
            return SK1PaymentService(orderStore: store)
        }
    }

}
