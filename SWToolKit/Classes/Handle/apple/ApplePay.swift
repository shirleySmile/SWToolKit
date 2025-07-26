//
//  ApplePay.swift
//  SWToolKit
//
//  Created by shirley on 2022/4/8.
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



public extension ApplePay {
    
    /// 支付结果错误的类型
    enum ResultFailType:Int {
        /// 用户取消购买
        case buyCancel
        /// 用户购买失败
        case buyFail
        
        /// 用户取消恢复购买
        case restoreCancel
        /// 用户恢复购买失败
        case restoreFail
        
        /// 有商品Id，但是苹果内购中无商品
        case noOrder
        /// 购买超时
        case timeout
        /// 不可进行购买
        case cannotPayments
        
        /// 其他 (未知错误)
        case other
        
    }

    /// 开始支付时错误的类型
    enum StartFailType:Int {
        /// 购买的产品Id为空
        case productIdNull
        /// 正在购买新内容
        case purchasing
        /// 正在恢复购买
        case restoring
    }
    
    /// 支付状态
    enum PaymentType:Int {
        /// 购买
        case purchase
        /// 恢复购买
        case restore
    }
    
}


public class ApplePay: NSObject {
    
    public static let share = ApplePay()

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
        print("苹果内购开始处理....")
    }
    
    ///支付代理
    public weak var delegate:ApplePayDelegate?
    
    private var request:SKProductsRequest?

    /// 苹果内购Id
    private var aProductId:String?
    private var currPaymentType:PaymentType?
    /// 购买定时器
    private var paymentTimer:Timer?
    /// 超时时间
    private var timeoutInterval: TimeInterval = 20.0
    
    
    ///开始支付
    public func pay(productId:String) -> ApplePay.StartFailType? {
        guard productId.count > 0 else { return .productIdNull }
        /// 有产品ID  (说明不是在购买中就是在恢复中)
        if let currPaymentType {
            return (currPaymentType == .restore) ? .restoring : .purchasing
        }
        self.clearDataHandle()
        self.currPaymentType = .purchase
        self.startPay(pId: productId)
        return nil
    }
    
    ///恢复购买
    public func restore() -> ApplePay.StartFailType? {
        if let currPaymentType {
            return (currPaymentType == .restore) ? .restoring : .purchasing
        }
        self.clearDataHandle()
        self.currPaymentType = .restore
        self.startRestore()
        return nil
    }
    
    /// 清除本地已购买的数据
    public func finish() {
        self.clearDataHandle()
    }
    
    
    /// 获取购买凭证
    public func getReceiptInfo() -> String? {
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            let receptInfo = getReceipt()
            if receptInfo.receiptStr.count > 0 {
                return receptInfo.receiptStr
            }
        }
        return nil
    }

    /// 刷新本地票据
    public func refreshLocalReceiptInfo() {
        let refreshRequest = SKReceiptRefreshRequest()
        refreshRequest.delegate = self
        refreshRequest.start()
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
    }
    
    ///结果处理并将支付结果返回给调用端
    private func failResultHandle(type:ResultFailType, msg:String){
        self.clearDataHandle()
        delegate?.applePayFail(pay: self, type: type, errorMsg: msg)
    }
    
    /// 超时
    @objc private func paymentTimeOut() {
        self.request?.cancel()
        self.failResultHandle(type: .timeout, msg: "超时未处理")
    }

    //MARK: ---------------刷新票据-----------------
    private func refreshReceiptInfo() {
    
    }

    
    //MARK: ---------------开始支付-----------------
    ///开始支付
    private func startPay(pId:String) {
        if SKPaymentQueue.canMakePayments() {
            print("--------请求对应的产品信息------------\n--------请求对应的产品信息: \(String(describing: pId))")
            self.aProductId = pId
            let set:Set<String> = [pId]
            self.paymentTimer = Timer.scheduledTimer(timeInterval: timeoutInterval, target: self, selector: #selector(paymentTimeOut), userInfo: nil, repeats: false)
            request = SKProductsRequest.init(productIdentifiers: set)
            request?.delegate = self;
            request?.start()
        }else{
            print("--------不允许程序内付费------------");
            self.failResultHandle(type: .cannotPayments, msg: "不允许程序内付费")
        }
    }
    
    /// 开始恢复购买
    private func startRestore() {
        self.paymentTimer = Timer.scheduledTimer(timeInterval: timeoutInterval, target: self, selector: #selector(paymentTimeOut), userInfo: nil, repeats: false)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // 获取凭证
    private func getReceipt() -> (msg:String, receiptStr:String) {
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            do {
                let receiptData = try? Data(contentsOf: receiptURL)
                if let encodeStr = receiptData?.base64EncodedString() {
                    return ("苹果内购成功获取数据", encodeStr)
                }else{
                    return ("苹果服务器解析出错", "")
                }
            } catch {
                return (error.localizedDescription, "")
            }
        }else{
            return ("没有购买信息", "")
        }
    }

}


//MARK: ---------------SKProductsRequestDelegate-----------------
extension ApplePay: SKProductsRequestDelegate{
    
    // 收到产品反馈消息
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("------收到产品反馈消息------")
        let product:[SKProduct] = response.products;
        if product.count == 0 {
            print("------没有商品1------")
            self.request?.cancel()
            failResultHandle(type: .noOrder, msg: "没有该商品1")
            return
        }
        print("productID:\(response.invalidProductIdentifiers), 产品付费数量:\(product.count)")
        
        var prod:SKProduct?
        for pro in product {
            print("---------商品信息下----------")
            print(pro.description, pro.localizedTitle, pro.localizedDescription, pro.price, pro.productIdentifier)
            print("---------商品信息上----------")
            if pro.productIdentifier == (self.aProductId ?? "") {
                prod = pro
            }
        }
        guard let prod else {
            print("------没有商品2------")
            self.request?.cancel()
            failResultHandle(type: .noOrder, msg: "没有该商品2")
            return
        }
        print("-------发送购买请求-------")
        let payment = SKPayment.init(product: prod)
        // 添加一个交易队列观察者
        SKPaymentQueue.default().add(payment)
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return delegate?.shouldAddStorePayment() ?? false
    }
    
}



//MARK: ---------------SKRequestDelegate-----------------
extension ApplePay:SKRequestDelegate {
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("-------购买失败-------\(error)")
        failResultHandle(type: .buyFail, msg: error.localizedDescription)
    }
    
    public func requestDidFinish(_ request: SKRequest) {
        print("-------请求结束--可能会多次回调-----")
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
                if receptInfo.receiptStr.count > 0{
                    self.clearDataHandle()
                    self.delegate?.applePayRestore(pay: self, encode: receptInfo.receiptStr)
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
            print("Transaction error: \(error.localizedDescription)")
            msg = error.localizedDescription
        }else{
            type = .restoreCancel
            msg = "用户取消交易"
        }
        failResultHandle(type: type, msg: msg)
    }
    
    // 支付状态变更
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("=============", transactions)
        for trans in transactions {
            switch trans.transactionState {
            case .purchasing:
                debugPrint("==商品添加进列表==")
            case .purchased:
                //订阅特殊处理
                if(trans.original != nil){
                    //如果是自动续费的订单originalTransaction会有内容
                    debugPrint("==自动续费的订单==")
                }else{
                    debugPrint("==一次购买交易完成==")
                }
                if let currPaymentType, currPaymentType == .purchase {
                    /// 用户购买，并且不是恢复购买的按钮，app启动后的回调不处理
                    completeTransaction(trans)
                }
                SKPaymentQueue.default().finishTransaction(trans)
            case .failed:
                print("==交易失败==");
                failedTransaction(trans)
                SKPaymentQueue.default().finishTransaction(trans)
            case .restored:
                debugPrint("==恢复购买==")
                if let error = trans.error as? SKError {
                    SKPaymentQueue.default().finishTransaction(trans)
                    failResultHandle(type: .restoreFail, msg: error.localizedDescription)
                }
            case .deferred:
                debugPrint("==交易延期==");
            default:
                print("==还有其他情况==")
                SKPaymentQueue.default().finishTransaction(trans)
                failResultHandle(type: .other, msg: "未知问题:\(trans.transactionState.rawValue)")
            }
        }
    }
}


/// 结果处理
extension ApplePay {
    
    //交易结束,当交易结束后还要去appstore上验证支付信息是否都正确,只有所有都正确后,我们就可以给用户方法我们的虚拟物品了。
    private func completeTransaction(_ transaction: SKPaymentTransaction){
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            let receptInfo = getReceipt()
            if receptInfo.receiptStr.count > 0, let aProductId {
                self.delegate?.applePaySuccess(pay: self, productId: aProductId, encode: receptInfo.receiptStr)
                self.clearDataHandle()
            }else{
                failResultHandle(type: .buyFail, msg: receptInfo.msg)
            }
        }else{
            // 如果凭证为空，则再发一次凭证请求
            failResultHandle(type: .buyFail, msg: "苹果服务器出错，请联系客服确认问题")
        }
    }
    
    ///购买失败
    private func failedTransaction(_ transaction: SKPaymentTransaction){
        var msg = ""
        var type:ResultFailType = .buyFail
        if let error = transaction.error as? SKError, error.code != .paymentCancelled {
            print("Transaction error: \(error.localizedDescription)")
            msg = error.localizedDescription
        }else{
            type = .buyCancel
            msg = "交易已取消"
        }
        failResultHandle(type: type, msg: msg)
    }
    
    
}
