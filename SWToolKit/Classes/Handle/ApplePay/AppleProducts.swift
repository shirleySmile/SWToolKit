//
//  AppleProducts.swift
//  Pods
//
//  Created by muwa on 2025/10/30.
//

import Foundation
import StoreKit

class AppleProducts:NSObject {
    
    
    private var products:[SKProduct]?
    private var request:SKProductsRequest?

    /// 得到的商品回调
    private var productClosure:((SKProduct?)->Void)?
    private var productId:String?
    
    /// 获取购买的产品信息
    func getProducts(productId:String, completed:((SKProduct?)->Void)?) {
        self.productId = productId
        if let info = self.getProdictInfo()  {
            applePayLog.add(type: .product, title: "产品回调", des: "已从本地获取内购信息")
            completed?(info)
            self.cancelHandle()
            return
        }
        self.productClosure = completed
        if request == nil {
            let set:Set<String> = [productId]
            request = SKProductsRequest.init(productIdentifiers: set)
            request?.delegate = self;
        }
        request?.start()
    }
    
    
    /// 刷新购买数据
    func reloadData() {
        if request == nil {
            request = SKProductsRequest.init()
            request?.delegate = self;
        }
        request?.start()
    }
    
    
    /// 取消购买
    func cancel() {
        applePayLog.add(type: .product, title: "产品回调", des: "外部调用取消购买")
        self.cancelHandle()
    }
    

    
    private func getProdictInfo() -> SKProduct? {
        if let products, products.count > 0 {
            for (idx, pro) in products.enumerated() {
                debugPrint("==SWToolKit==" + "----产品回调-----商品信息下----------")
                let proStr:String = pro.productIdentifier + "," + pro.localizedTitle + "," + pro.price.stringValue
                debugPrint("==SWToolKit==" + "----产品回调-----商品信息上----------")
                applePayLog.add(type: .product, title: "产品回调", des: "产品信息\(idx+1)(\(proStr))")
                if let productId, pro.productIdentifier == productId {
                    return pro
                }
            }
        }
        return nil
    }
    
    
    private func cancelHandle() {
        self.request?.delegate = nil
        self.request?.cancel()
        self.request = nil
        self.productId = nil
        self.productClosure = nil
    }
    
}


extension AppleProducts: SKProductsRequestDelegate {
    
    // 收到产品反馈消息
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        debugPrint("==SWToolKit==" + "----产品回调-----收到产品回馈信息----------")
        applePayLog.add(type: .product, title: "产品回调", des: "收到产品反馈消息")
        self.products = response.products;
        let pCount:Int = (self.products?.count ?? 0)
        if pCount == 0 {
            applePayLog.add(type: .product, title: "产品回调", des: "可购买的产品为空")
            self.productClosure?(nil)
            self.cancelHandle()
            return
        }
        
        applePayLog.add(type: .product, title: "产品回调", des: "产品付费数量:\(pCount)")
        let info = self.getProdictInfo()
        self.productClosure?(info)
        self.cancelHandle()
    }
    
    func requestDidFinish(_ request: SKRequest) {
        debugPrint("==SWToolKit==" + "----产品回调-----请求结束----可能会多次回调------")
    }
    
    func request(_ request: SKRequest, didFailWithError error: any Error) {
        debugPrint("==SWToolKit==" + "----产品回调-----请求产品信息失败----------")
        applePayLog.add(type: .product, title: "产品回调", des: "获取产品信息失败\(error.localizedDescription)")
        self.productClosure?(nil)
        self.cancelHandle()
    }
    
    
}



