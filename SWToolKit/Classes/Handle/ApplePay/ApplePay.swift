//
//  ApplePay.swift
//

import Foundation
import StoreKit


public protocol ApplePayDelegate:NSObject {
    
    /// 支付失败结果的代理
    func applePayFail(pay:ApplePay, type:ApplePay.ResultFailType, errorMsg:String)
    
    /// 支付成功的代理
    func applePaySuccess(pay:ApplePay, productId: String, encode: String)

    /// 恢复购买
    func applePayRestore(pay:ApplePay, encode: String)
    
    /// 检测是否可以从AppStore促销点击购买处理
    func shouldAddStorePayment() -> Bool
    
}



public class ApplePay: NSObject {
    
    public static let share = ApplePay()

    private let payLog = ApplePayLog()
    
    deinit{
        ///删除一个交易队列观察者
        SKPaymentQueue.default().remove(self)
    }
    
    private override init() {
        super.init()
        /// 添加监听观察者
        SKPaymentQueue.default().add(self)
    }

    public func startHandle() {
        MessageInfo.print("苹果内购开始处理....")
    }
    
    ///支付代理
    public weak var delegate:ApplePayDelegate?
    
    private var request:SKProductsRequest?
    /// 刷新本地数据
    private var refreshInfo:ApplyPayRefresh?

    /// 苹果内购Id
    private var aProductId:String?
    private var currPaymentType:PaymentType?
    /// 购买定时器
    private var paymentTimer:Timer?
    /// 超时时间
    public var timeoutInterval: TimeInterval = 30.0
    
    ///开始支付
    public func pay(productId:String) -> ApplePay.StartFailType? {
        guard productId.count > 0 else {
            payLog.add(type: .start, title: "开始购买失败", des: "没有产品Id")
            return .productIdNull
        }
        /// 有产品ID  (说明不是在购买中就是在恢复中)
        if let currPaymentType {
            payLog.add(type: .start, title: "开始购买失败", des: "当前正在进行\(currPaymentType.des())")
            return (currPaymentType == .restore) ? .restoring : .purchasing
        }
        self.clearDataHandle()
        payLog.add(type: .start, title: "开始购买", des: "1")
        self.currPaymentType = .purchase
        self.startPay(pId: productId)
        return nil
    }
    
    ///恢复购买
    public func restore() -> ApplePay.StartFailType? {
        if let currPaymentType {
            payLog.add(type: .start, title: "开始恢复失败", des: "当前正在进行\(currPaymentType.des())")
            return (currPaymentType == .restore) ? .restoring : .purchasing
        }
        self.clearDataHandle()
        payLog.add(type: .start, title: "开始恢复", des: "1")
        self.currPaymentType = .restore
        self.startRestore()
        return nil
    }
    
    /// 清除多余数据
    public func finish() {
        self.clearDataHandle()
    }

    /// 获取本地购买凭证
    public func getLocalReceiptInfo(back:((String?)->Void)?) {
        if self.refreshInfo == nil {
            payLog.add(type: .start, title: "本地票据", des: "开始")
            self.refreshInfo = ApplyPayRefresh()
            self.refreshInfo?.refreshLocalReceiptInfo { [weak self] error in
                self?.payLog.add(type: .start, title: "本地票据", des: "刷新本地票据(\((error as? NSError)?.domain ?? "成功"))")
                self?.refreshInfo = nil
                let info = self?.getReceipt()
                if let receiptStr = info?.receiptStr {
                    back?(receiptStr)
                    self?.payLog.add(type: .end, title: "本地票据", des: "本地有票据")
                } else {
                    back?(nil)
                    self?.payLog.add(type: .end, title: "本地票据", des: "本地无票据\(info?.msg ?? "")")
                }
            }
        }
    }

    /// 仅刷新本地票据
    public func refreshLocalReceiptInfo(back:((Bool)->Void)?) {
        if self.refreshInfo == nil {
            self.refreshInfo = ApplyPayRefresh()
            self.refreshInfo?.refreshLocalReceiptInfo { [weak self] error in
                self?.refreshInfo = nil
                back?((error == nil))
            }
        }
    }
    
    /// 日志
    public func logInfo() -> [String] {
        return payLog.getInfo()
    }
    
}




extension ApplePay {
    
    /// 清理数据
    private func clearDataHandle() {
        self.paymentTimer?.invalidate()
        self.paymentTimer = nil
        self.aProductId = nil
        self.request?.delegate = nil
        self.request?.cancel()
        self.request = nil
        self.currPaymentType = nil
        payLog.add(type: .clear, title: "清理数据", des: "清空所有数据")
    }
    
    ///结果处理并将支付结果返回给调用端
    private func failResultHandle(type:ResultFailType, msg:String){
        payLog.add(type: .end, title: currPaymentType?.des() ?? "未知", des: type.des() + ":\(msg)" )
        self.clearDataHandle()
        delegate?.applePayFail(pay: self, type: type, errorMsg: msg)
    }
    
    /// 超时
    @objc private func paymentTimeOut() {
        self.request?.cancel()
        self.failResultHandle(type: .timeout, msg: "超时未处理")
    }
    
    //MARK: ---------------开始支付-----------------
    ///开始支付
    private func startPay(pId:String) {
        if SKPaymentQueue.canMakePayments() {
            self.aProductId = pId
            let set:Set<String> = [pId]
            self.paymentTimer = Timer.scheduledTimer(timeInterval: timeoutInterval, target: self, selector: #selector(paymentTimeOut), userInfo: nil, repeats: false)
            request = SKProductsRequest.init(productIdentifiers: set)
            request?.delegate = self;
            request?.start()
            payLog.add(type: .start, title: "开始购买", des: "开始请求票据")
        }else{
            self.failResultHandle(type: .cannotPayments, msg: "不允许程序内付费")
        }
    }
    
    /// 开始恢复购买
    private func startRestore() {
        self.paymentTimer = Timer.scheduledTimer(timeInterval: timeoutInterval, target: self, selector: #selector(paymentTimeOut), userInfo: nil, repeats: false)
        SKPaymentQueue.default().restoreCompletedTransactions()
        payLog.add(type: .start, title: "开始恢复", des: "开始请求恢复数据")
    }


}


//MARK: ---------------SKProductsRequestDelegate-----------------
extension ApplePay: SKProductsRequestDelegate{
    
    // 收到产品反馈消息
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        payLog.add(type: .product, title: "产品回调", des: "收到产品反馈消息")
        let product:[SKProduct] = response.products;
        if product.count == 0 {
            payLog.add(type: .product, title: "产品回调", des: "可购买的产品为空")
            self.request?.cancel()
            failResultHandle(type: .noOrder, msg: "可选的产品为空")
            return
        }
        
        payLog.add(type: .product, title: "产品回调", des: "产品付费数量:\(product.count)")
        
        var prod:SKProduct?
        for (idx, pro) in product.enumerated() {
            MessageInfo.print("---------商品信息下----------")
            var proStr:String = pro.productIdentifier + "," + pro.localizedTitle + "," + pro.price.stringValue
            MessageInfo.print("---------商品信息上----------")
            payLog.add(type: .product, title: "产品回调", des: "产品信息\(idx+1)(\(proStr))")
            if pro.productIdentifier == (self.aProductId ?? "") {
                prod = pro
            }
        }
        guard let prod else {
            payLog.add(type: .product, title: "产品回调", des: "苹果商品内购产品Id与用户申请购买Id不匹配")
            self.request?.cancel()
            failResultHandle(type: .noOrder, msg: "没有找到指定商品")
            return
        }
        
        let payment = SKPayment.init(product: prod)
        // 添加一个交易队列观察者
        SKPaymentQueue.default().add(payment)
        payLog.add(type: .product, title: "开始购买", des: "发送购买请求")
    }
    
    /// 当用户从应用商店发起应用内购买操作时发送此消息
    public func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return delegate?.shouldAddStorePayment() ?? false
    }
    
}



//MARK: ---------------SKRequestDelegate-----------------
extension ApplePay:SKRequestDelegate {
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        MessageInfo.print("-------购买失败-------\(error)")
        failResultHandle(type: .buyFail, msg: error.localizedDescription)
    }
    
    public func requestDidFinish(_ request: SKRequest) {
        MessageInfo.print("-------请求结束--可能会多次回调-----")
    }
    
}


//MARK: ---------------SKPaymentTransactionObserver-----------------
extension ApplePay:SKPaymentTransactionObserver {
    
    // 恢复成功后的回调
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        if queue.transactions.count > 0 {
            /// 说明有可恢复购买的产品
            if let receiptURL = Bundle.main.appStoreReceiptURL, FileManager.default.fileExists(atPath: receiptURL.path) {
                let receptInfo = getReceipt()
                if let receiptStr = receptInfo.receiptStr {
                    self.delegate?.applePayRestore(pay: self, encode: receiptStr)
                    payLog.add(type: .end, title: "恢复购买", des: "本地有票据")
                    self.clearDataHandle()
                }else{
                    failResultHandle(type: .restoreFail, msg: receptInfo.msg)
                }
            }else{
                // 没有可恢复的购买项
                failResultHandle(type: .restoreFail, msg: "没有可恢复的购买项")
            }
        }else{
            // 没有可恢复的购买项
            failResultHandle(type: .restoreFail, msg: "没有可恢复的购买项")
        }
    }
    
    // 恢复失败后的回调
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        // 没有可恢复的购买项
        var msg:String = ""
        var type:ResultFailType = .restoreFail
        if let error = error as? SKError, error.code != .paymentCancelled {
            msg = error.localizedDescription
        }else{
            type = .restoreCancel
            msg = "用户取消交易"
        }
        failResultHandle(type: type, msg: msg)
    }
    
    // 支付状态变更
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        let info:[String] = transactions.compactMap({ trans in
            return trans.description
        })
        payLog.add(type: .statusChange, title: "购买事物变更", des: "回调信息(" + info.toJson() + ")")
        for trans in transactions {
            switch trans.transactionState {
            case .purchasing:
                payLog.add(type: .statusChange, title: "购买事物变更", des: "商品添加进列表")
            case .purchased:
                //订阅特殊处理
                if(trans.original != nil){
                    //如果是自动续费的订单originalTransaction会有内容
                    payLog.add(type: .statusChange, title: "购买事物变更", des: "自动续费的订单")
                }else{
                    payLog.add(type: .statusChange, title: "购买事物变更", des: "一次购买交易完成")
                }
                if let currPaymentType, currPaymentType == .purchase, let aProductId {
                    /// 用户购买，并且不是恢复购买的按钮，app启动后的回调不处理
                    completeTransaction(trans, pId: aProductId)
                }
                SKPaymentQueue.default().finishTransaction(trans)
            case .failed:
                payLog.add(type: .statusChange, title: "购买事物变更", des: "交易失败")
                failedTransaction(trans)
                SKPaymentQueue.default().finishTransaction(trans)
            case .restored:
                payLog.add(type: .statusChange, title: "购买事物变更", des: "恢复购买")
                if let error = trans.error as? SKError {
                    SKPaymentQueue.default().finishTransaction(trans)
                    failResultHandle(type: .restoreFail, msg: error.localizedDescription)
                }
            case .deferred:
                payLog.add(type: .statusChange, title: "购买事物变更", des: "交易延期")
            default:
                payLog.add(type: .statusChange, title: "购买事物变更", des: "其他情况(\(trans.transactionState.rawValue)")
                failResultHandle(type: .other, msg: "未知问题:\(trans.transactionState.rawValue)")
                SKPaymentQueue.default().finishTransaction(trans)
            }
        }
    }
}


/// 结果处理
extension ApplePay {
    
    //交易结束,当交易结束后还要去appstore上验证支付信息是否都正确,只有所有都正确后,我们就可以给用户方法我们的虚拟物品了。
    private func completeTransaction(_ transaction: SKPaymentTransaction, pId:String){
        let receptInfo = self.getReceipt()
        if let receiptStr = receptInfo.receiptStr {
            payLog.add(type: .end, title: "购买新产品", des: "本地有票据")
            self.delegate?.applePaySuccess(pay: self, productId: pId, encode: receiptStr)
            self.clearDataHandle()
        } else {
            // 如果凭证为空，则再发一次凭证请求
            failResultHandle(type: .buyFail, msg: receptInfo.msg)
        }
    }
    
    ///购买失败
    private func failedTransaction(_ transaction: SKPaymentTransaction){
        var msg = ""
        var type:ResultFailType = .buyFail
        if let error = transaction.error as? SKError, error.code != .paymentCancelled {
            msg = error.localizedDescription
        }else{
            type = .buyCancel
            msg = "交易已取消"
        }
        failResultHandle(type: type, msg: msg)
    }
    
    
    // 获取凭证
    private func getReceipt() -> (msg:String, receiptStr:String?) {
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            do {
                let receiptData = try? Data(contentsOf: receiptURL)
                if let encodeStr = receiptData?.base64EncodedString(), encodeStr.count > 0 {
                    return ("苹果内购成功获取数据", encodeStr)
                }else{
                    return ("苹果服务器解析出错", nil)
                }
            } catch {
                return (error.localizedDescription, nil)
            }
        }else{
            return ("没有购买凭证", nil)
        }
    }
    
}
