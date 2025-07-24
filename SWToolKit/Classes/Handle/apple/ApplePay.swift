//
//  ApplePay.swift
//  ProjCommon
//
//  Created by shirley on 2022/4/8.
//

import Foundation
import StoreKit


public protocol ApplePayDelegate:NSObject {
    
    /// 支付失败结果的代理
    func applePayFail(pay:ApplePay, type:ApplePay.FailType, errorMsg:String?)
    
    /// 支付成功的代理
    func applePaySuccess(pay:ApplePay, orderNo: String, encode: String)

    /// 恢复购买
    func applePayRestore(pay:ApplePay, encode: String)
    
    /// 检测是否可以从促销点击购买处理
    func shouldAddStorePayment() -> Bool
    
}

public extension ApplePay {
    
    enum FailType {
        /// 用户取消购买
        case buyCancel
        /// 用户购买失败
        case buyFail
        
        /// 用户取消恢复购买
        case restoreCancel
        /// 用户恢复购买失败
        case restoreFail
        
        /// 无商品
        case noOrder
        /// 其他
        case other
    }
    
}


public class ApplePay: NSObject {
    
    @MainActor public static let share = ApplePay()

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
    
    var request:SKProductsRequest?
    var refreshReq:SKReceiptRefreshRequest?
    
    /// 订单信息 pId:apple内购的产品ID orderId: 服务器生成的订单
    public private(set) var aProductInfo:(pId:String, orderNo:String)?
    
    ///开始支付
    public func pay(orderNo:String, productId:String) -> Bool {
        if let pInfo = aProductInfo,  pInfo.pId.count > 0 {
            return false
        }else{
            if productId.count > 0 && orderNo.count > 0 {
                aProductInfo = (productId, orderNo)
                let result = startPay(pId: productId)
                if !result {
                    aProductInfo = nil
                }
                return result
            }else{
                return false
            }
        }
    }
    
    ///恢复购买
    public func restore() -> Bool {
        if let pInfo = aProductInfo,  pInfo.pId.count > 0 {
            return false
        }else{
            aProductInfo = ("-1", "")
            SKPaymentQueue.default().restoreCompletedTransactions()
            return true
        }
    }
    
    /// 清除本地已购买的数据
    /// transactionId 原始订单ID
    public func finish() {
        aProductInfo = nil
        request = nil
    }
    
    
    /// 获取购买凭证
    public func getReceiptInfo() -> String?{
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            let receptInfo = getReceipt()
            if receptInfo.receiptStr.count > 0 {
                return receptInfo.receiptStr
            }
        }
        return nil
    }
    
    

}




extension ApplePay {
    
    
    ///结果处理并将支付结果返回给调用端
    private func failResultHandle(type:FailType, msg:String){
        delegate?.applePayFail(pay: self, type: type, errorMsg: msg)
        aProductInfo = nil
        request = nil
    }
    

    //MARK: ---------------刷新票据-----------------
    private func refreshPayData() {
        
//            Transaction.all
//        AppTransaction.shared
        
    }
    
    
    
    //MARK: ---------------支付-----------------
    
    ///开始支付
    private func startPay(pId:String) -> Bool {
        if SKPaymentQueue.canMakePayments() {
            print("--------请求对应的产品信息------------")
            print("请求对应的产品信息: \(String(describing: pId))")
            
            let set:Set<String> = [pId]
            request = SKProductsRequest.init(productIdentifiers: set)
            request?.delegate = self;
            request?.start()
            return true
        }else{
            print("--------不允许程序内付费------------");
            return false
        }
    }
    
    ///购买失败
    private func failedTransaction(transaction: SKPaymentTransaction){
        var msg = ""
        var type:FailType = .buyFail
        if let error = transaction.error as? SKError, error.code != .paymentCancelled{
            print("Transaction error: \(error.localizedDescription)")
            msg = error.localizedDescription
        }else{
            type = .buyCancel
            msg = "交易已取消"
        }
        SKPaymentQueue.default().finishTransaction(transaction)
        failResultHandle(type: type, msg: msg)
    }
    
    //交易结束,当交易结束后还要去appstore上验证支付信息是否都正确,只有所有都正确后,我们就可以给用户方法我们的虚拟物品了。
    private func completeTransaction(transaction: SKPaymentTransaction){
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            let receptInfo = getReceipt()
            if receptInfo.receiptStr.count > 0, let pInfo = aProductInfo {
                self.delegate?.applePaySuccess(pay: self, orderNo: pInfo.orderNo, encode: receptInfo.receiptStr)
            }else{
                failResultHandle(type: .buyFail, msg: receptInfo.msg)
            }
        }else{
            // 如果凭证为空，则再发一次凭证请求
            failResultHandle(type: .buyFail, msg: "苹果服务器出错，请联系客服确认问题")
        }
        SKPaymentQueue.default().finishTransaction(transaction)
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
    
    ///收到产品反馈消息
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("------收到产品反馈消息------")
        let product:[SKProduct] = response.products;
        if product.count == 0 {
            print("------没有商品------")
            failResultHandle(type: .noOrder, msg: "没有该商品")
            return
        }
        print("productID:\(response.invalidProductIdentifiers), 产品付费数量:\(product.count)")
        
        var prod:SKProduct?
        for pro in product {
            print("---------商品信息下----------")
            print(pro.description, pro.localizedTitle, pro.localizedDescription, pro.price, pro.productIdentifier)
            print("---------商品信息上----------")
            if pro.productIdentifier == (self.aProductInfo?.pId ?? "") {
                prod = pro
            }
        }
        if prod != nil {
            print("-------发送购买请求-------")
            let payment = SKPayment.init(product: prod!)
            ///添加一个交易队列观察者
            SKPaymentQueue.default().add(payment)
        }
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
        print("-------请求结束-------")
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
        var type:FailType = .restoreFail
        if let error = error as? SKError, error.code != .paymentCancelled {
            print("Transaction error: \(error.localizedDescription)")
            msg = error.localizedDescription
        }else{
            type = .restoreCancel
            msg = "用户取消交易"
        }
        failResultHandle(type: type, msg: msg)
    }
    
    /// 支付状态变更
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
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
                if let pInfo = aProductInfo, pInfo.pId != "-1" {
                    /// 用户点击购买，并且不是恢复购买的按钮，   app启动后的回调不处理
                    completeTransaction(transaction:trans)
                }
                SKPaymentQueue.default().finishTransaction(trans)
            case .failed:
                print("==交易失败==");
                failedTransaction(transaction: trans)
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
            }
        }
    }
}
