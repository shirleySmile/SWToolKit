//
//  ApplePayManager.swift
//

import Foundation


public protocol ApplePayManagerDelegate: NSObject {
    
    /// 支付失败结果的代理
    func applePayFail(pay: ApplePayManager, type: ApplePayManager.ResultFailType, errorMsg: String)
    
    /// 支付成功的代理
    func applePaySuccess(pay: ApplePayManager, productId: String, orderId: String?, encode: String)

    /// 恢复购买
    func applePayRestore(pay: ApplePayManager, encode: String)
    
    /// 检测是否可以从AppStore促销点击购买处理
    func shouldAddStorePayment() -> Bool
    
}


public class ApplePayManager: NSObject {
    
    
    public static let share = ApplePayManager()
    /// 刷新本地数据
    private var refreshInfo: ApplyPayRefresh?
    /// 内购处理（根据系统版本选择 StoreKit 1 或 StoreKit 2）
    private let service: ApplePayService

    fileprivate override init() {
        self.service = ApplePayServiceFactory.makeService()
        super.init()
        self.service.serviceDelegate = self
    }
 
    /// 苹果内购Id
    private var aProductId: String?
    private var currPaymentType: PaymentType?
    
    /// 超时定时器
    private var paymentTimer: Timer?
    
  
    ///支付代理
    public weak var delegate: ApplePayManagerDelegate?
    
    /// 超时时间
    public var timeoutInterval: TimeInterval = 150.0
    
    
    public func initData() {
        debugPrint("==SWToolKit==" + "苹果内购开始处理....")
    }

    ///开始支付
    public func pay(productId: String) -> ApplePayManager.StartFailType? {
        return self.pay(productId: productId, orderId: productId)
    }

    ///开始支付
    public func pay(productId: String, orderId: String) -> ApplePayManager.StartFailType? {
        guard self.service.checkCanPayment() else {
            let type: ApplePayManager.StartFailType = .cannotPayments
            applePayLog.add(type: .start, title: "开始购买失败", des: type.des())
            return type
        }
        guard productId.count > 0 else {
            let type: ApplePayManager.StartFailType = .productIdNull
            applePayLog.add(type: .start, title: "开始购买失败", des: type.des())
            return type
        }
        /// 有产品ID  (说明不是在购买中就是在恢复中)
        if let currPaymentType {
            let type: ApplePayManager.StartFailType = ((currPaymentType == .restore) ? .restoring : .purchasing)
            applePayLog.add(type: .start, title: "开始购买失败", des: "当前正在进行" + type.des())
            return type
        }
        self.clearDataHandle()
        applePayLog.add(type: .start, title: "开始购买", des: "1")
        self.currPaymentType = .purchase
        
        self.requestProduct(pId: productId, orderId: orderId)
        return nil
    }
    
    ///恢复购买
    public func restore() -> ApplePayManager.StartFailType? {
        if let currPaymentType {
            let type: ApplePayManager.StartFailType = ((currPaymentType == .restore) ? .restoring : .purchasing)
            applePayLog.add(type: .start, title: "开始恢复失败", des: "当前正在进行" + type.des())
            return type
        }
        self.clearDataHandle()
        applePayLog.add(type: .start, title: "开始恢复", des: "1")
        self.currPaymentType = .restore
        self.startRestore()
        return nil
    }
    
    /// 清除多余数据
    public func finish() {
        self.clearDataHandle()
    }

    /// 获取本地购买凭证
    public func getLocalReceiptInfo(back: ((String?) -> Void)?) {
        if self.refreshInfo == nil {
            applePayLog.add(type: .start, title: "本地票据", des: "开始")
            self.refreshInfo = ApplyPayRefresh()
            self.refreshInfo?.refreshLocalReceiptInfo { [weak self] error in
                applePayLog.add(type: .start, title: "本地票据", des: "刷新本地票据(\((error as? NSError)?.domain ?? "成功"))")
                self?.refreshInfo = nil
                let receiptStr = self?.service.getLocalReceiptInfo()
                back?(receiptStr)
            }
        }
    }

    /// 仅刷新本地票据
    public func refreshLocalReceiptInfo(back: ((Bool) -> Void)?) {
        if self.refreshInfo == nil {
            self.refreshInfo = ApplyPayRefresh()
            self.refreshInfo?.refreshLocalReceiptInfo { [weak self] error in
                self?.refreshInfo = nil
                back?((error == nil))
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
    
    /// 清理数据
    private func clearDataHandle() {
        self.paymentTimer?.invalidate()
        self.paymentTimer = nil
        self.aProductId = nil
        self.service.cancel()
        self.currPaymentType = nil
        applePayLog.add(type: .clear, title: "清理数据", des: "清空所有数据")
    }
    
    ///结果处理并将支付结果返回给调用端
    private func failResultHandle(type: ResultFailType, msg: String) {
        applePayLog.add(type: .end, title: currPaymentType?.des() ?? "未知", des: type.des() + ":\(msg)" )
        self.clearDataHandle()
        delegate?.applePayFail(pay: self, type: type, errorMsg: msg)
    }
    
    /// 超时
    @objc private func paymentTimeOut() {
        self.failResultHandle(type: .timeout, msg: "超时未处理")
    }
    
    //MARK: ---------------开始支付-----------------
    
    /// 开始恢复购买
    private func startRestore() {
        self.paymentTimer?.invalidate()
        self.paymentTimer = Timer.scheduledTimer(timeInterval: timeoutInterval, target: self, selector: #selector(paymentTimeOut), userInfo: nil, repeats: false)
        self.service.restore()
    }

    ///获得购买的产品信息
    private func requestProduct(pId: String, orderId: String) {
        self.aProductId = pId
        self.paymentTimer?.invalidate()
        self.paymentTimer = Timer.scheduledTimer(timeInterval: timeoutInterval, target: self, selector: #selector(paymentTimeOut), userInfo: nil, repeats: false)
        applePayLog.add(type: .start, title: "开始购买", des: "开始获得本地票据，若没有会从网络上请求")
        self.service.startPay(productId: pId, orderId: orderId)
    }
    
}


extension ApplePayManager: ApplePayServiceDelegate {
    
    func applePayServiceShouldAddStorePayment() -> Bool {
        return self.delegate?.shouldAddStorePayment() ?? false
    }
    
    func applePayServiceSuccess(receipt: String, orderId: String?) {
        self.delegate?.applePaySuccess(pay: self, productId: self.aProductId ?? "", orderId: orderId, encode: receipt)
        self.clearDataHandle()
    }
    
    func applePayServiceRestore(receipt: String) {
        self.delegate?.applePayRestore(pay: self, encode: receipt)
        self.clearDataHandle()
    }
    
    func applePayServiceFail(type: ResultFailType, message: String) {
        self.delegate?.applePayFail(pay: self, type: type, errorMsg: message)
        self.clearDataHandle()
    }

}
