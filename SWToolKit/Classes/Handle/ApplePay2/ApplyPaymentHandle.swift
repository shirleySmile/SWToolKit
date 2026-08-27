//
//  ApplyPaymentHandle.swift
//  Pods
//
//  Created by muwa on 2025/10/30.
//

import StoreKit
import Foundation


/// 使用 StoreKit 1 实现的苹果内购（iOS 26 及以上使用）
@MainActor
class ApplyPaymentHandle: NSObject, ApplePayService {
    
    /// 当前支付类型 购买or恢复
    private var currPaymentType: ApplePayManager.PaymentType?
    
    /// 苹果产品信息
    private var appleProducts: AppleProducts = .init()
    
    /// 数据回调
    weak var serviceDelegate: ApplePayServiceDelegate?
    
    deinit {
        /// 删除一个交易队列观察者
        SKPaymentQueue.default().remove(self)
    }
    
    override init() {
        super.init()
    }
    
    /// 是否已注册观察者
    private var isStarted = false
    
    /// 注册交易队列观察者
    func start() {
        guard !isStarted else { return }
        isStarted = true
        SKPaymentQueue.default().add(self)
    }
    
    /// 检测是否可以使用内购
    func checkCanPayment() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    /// 开始支付
    func startPay(productId: String, orderId: String) {
        self.currPaymentType = .purchase
        applePayLog.add(type: .start, title: "开始购买", des: "发送购买请求")
        self.appleProducts.getProducts(productId: productId) { [weak self] product in
            guard let self else { return }
            guard let product else {
                self.failResultHandle(type: .noOrder, msg: "没有找到指定商品")
                return
            }
            // 添加一个交易队列观察者
            let payment = SKMutablePayment(product: product)
            payment.applicationUsername = orderId
            SKPaymentQueue.default().add(payment)
        }
    }
    
    /// 恢复购买
    func restore() {
        self.currPaymentType = .restore
        applePayLog.add(type: .start, title: "开始恢复", des: "开始请求恢复数据")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    /// 获取本地购买凭证
    func getLocalReceiptInfo() -> String? {
        let info = self.getReceipt()
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
        self.appleProducts.cancel()
        self.clearData()
    }
    
    private func clearData() {
        self.currPaymentType = nil
    }
    
}


extension ApplyPaymentHandle {
    
    /// 结果处理并将支付结果返回给调用端
    private func failResultHandle(type: ApplePayManager.ResultFailType, msg: String) {
        applePayLog.add(type: .end, title: (currPaymentType?.des() ?? "未知") + "失败", des: type.des() + ":\(msg)")
        self.clearData()
        serviceDelegate?.applePayServiceFail(type: type, message: msg)
    }
}


//MARK: ---------------SKPaymentTransactionObserver-----------------
extension ApplyPaymentHandle: @preconcurrency SKPaymentTransactionObserver {
    
    /// 当用户从应用商店发起应用内购买操作时发送此消息
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return serviceDelegate?.applePayServiceShouldAddStorePayment() ?? false
    }
    
    // 恢复成功后的回调
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        /// 说明有可恢复购买的产品
        if let receiptURL = Bundle.main.appStoreReceiptURL, FileManager.default.fileExists(atPath: receiptURL.path) {
            let receptInfo = getReceipt()
            if let receiptStr = receptInfo.receiptStr {
                applePayLog.add(type: .end, title: "恢复购买", des: "本地有票据")
                self.serviceDelegate?.applePayServiceRestore(receipt: receiptStr)
                self.clearData()
            } else {
                failResultHandle(type: .restoreFail, msg: receptInfo.msg)
            }
        } else {
            // 没有可恢复的购买项
            failResultHandle(type: .restoreFail, msg: "没有可恢复的购买项")
        }

    }
    
    // 恢复失败后的回调
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        // 没有可恢复的购买项
        var msg: String = ""
        var type: ApplePayManager.ResultFailType = .restoreFail
        if let error = error as? SKError, error.code != .paymentCancelled {
            msg = error.localizedDescription
        } else {
            type = .restoreCancel
            msg = "用户取消交易"
        }
        failResultHandle(type: type, msg: msg)
    }
    
    // 支付状态变更
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        let info: [String] = transactions.compactMap({ trans in
            return trans.description
        })
        applePayLog.add(type: .statusChange, title: "购买事物变更", des: "回调信息(" + info.toJson() + ")")
        for trans in transactions {
            switch trans.transactionState {
            case .purchasing:
                applePayLog.add(type: .statusChange, title: "购买事物变更", des: "商品添加进列表")
            case .purchased:
                if trans.original != nil {
                    // 自动续费订单，交服务器验签，不当作新购买发货
                    applePayLog.add(type: .statusChange, title: "购买事物变更", des: "自动续费的订单")
                } else if trans.payment.applicationUsername == nil {
                    // AppStore 促销购买，发货，orderId 为空
                    applePayLog.add(type: .statusChange, title: "购买事物变更", des: "AppStore 促销购买")
                    completeTransaction(trans)
                } else {
                    // 主动购买，发货
                    applePayLog.add(type: .statusChange, title: "购买事物变更", des: "一次购买交易完成")
                    completeTransaction(trans)
                }
                SKPaymentQueue.default().finishTransaction(trans)
            case .failed:
                applePayLog.add(type: .statusChange, title: "购买事物变更", des: "交易失败")
                failedTransaction(trans)
                SKPaymentQueue.default().finishTransaction(trans)
            case .restored:
                applePayLog.add(type: .statusChange, title: "购买事物变更", des: "恢复购买")
                SKPaymentQueue.default().finishTransaction(trans)
            case .deferred:
                applePayLog.add(type: .statusChange, title: "购买事物变更", des: "交易延期")
                self.currPaymentType = nil
                self.serviceDelegate?.applePayServicePending()
            default:
                applePayLog.add(type: .statusChange, title: "购买事物变更", des: "其他情况(\(trans.transactionState.rawValue)")
                failResultHandle(type: .other, msg: "未知问题:\(trans.transactionState.rawValue)")
                SKPaymentQueue.default().finishTransaction(trans)
            }
        }
    }
}


/// 结果处理
extension ApplyPaymentHandle {
    
    // 交易结束,当交易结束后还要去appstore上验证支付信息是否都正确,只有所有都正确后,我们就可以给用户方法我们的虚拟物品了。
    private func completeTransaction(_ transaction: SKPaymentTransaction) {
        let receptInfo = self.getReceipt()
        if let receiptStr = receptInfo.receiptStr {
            applePayLog.add(type: .end, title: "购买新产品", des: "本地有票据")
            let orderId = transaction.payment.applicationUsername
            self.serviceDelegate?.applePayServiceSuccess(receipt: receiptStr, orderId: orderId)
            self.clearData()
        } else {
            // 如果凭证为空，则再发一次凭证请求
            failResultHandle(type: .buyFail, msg: receptInfo.msg)
        }
    }
    
    /// 购买失败
    private func failedTransaction(_ transaction: SKPaymentTransaction) {
        var msg = ""
        var type: ApplePayManager.ResultFailType = .buyFail
        if let error = transaction.error as? SKError, error.code != .paymentCancelled {
            msg = error.localizedDescription
        } else {
            type = .buyCancel
            msg = "交易已取消"
        }
        failResultHandle(type: type, msg: msg)
    }
    
    // 获取凭证
    private func getReceipt() -> (msg: String, receiptStr: String?) {
        if let receiptURL = Bundle.main.appStoreReceiptURL {
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
        } else {
            return ("没有购买凭证", nil)
        }
    }
    
}
