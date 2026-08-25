//
//  AppleProducts.swift
//  Pods
//
//  Created by muwa on 2025/10/30.
//

import Foundation
import StoreKit

class AppleProducts:NSObject {
    
    
    private var productDict:[String:SKProduct] = Dictionary()
    private var request:SKProductsRequest?

    /// 得到的商品回调
    private var productClosure:((SKProduct?)->Void)?
    private var productId:String?
    
    /// 获取购买的产品信息
    func getProducts(productId:String, completed:((SKProduct?)->Void)?) {
        self.productId = productId
        if let pInfo = self.productDict[productId] {
            applePayLog.add(type: .product, title: "获取商品信息", des: "已从本地获取内购信息")
            completed?(pInfo)
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
    func reloadData(_ ids:[String]) {
        if request == nil, ids.count > 0 {
            let set:Set<String> = Set(ids)
            applePayLog.add(type: .product, title: "刷新本地票据", des: "票据Id:\(ids.toJson())")
            request = SKProductsRequest.init(productIdentifiers: set)
            request?.delegate = self;
            request?.start()
        }
    }
    
    
    /// 取消
    func cancel() {
        applePayLog.add(type: .product, title: "清理数据", des: "外部调用取消")
        self.cancelHandle()
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
        applePayLog.add(type: .product, title: "商品回调", des: "收到产品反馈消息")
        let products = response.products;
        if products.count == 0 {
            applePayLog.add(type: .product, title: "商品回调", des: "可购买的产品为空")
            self.productClosure?(nil)
            self.cancelHandle()
            return
        }
        
        applePayLog.add(type: .product, title: "商品回调", des: "产品付费数量:\(products.count)")
        
        for (idx, pro) in products.enumerated() {
            self.productDict[pro.productIdentifier] = pro
            debugPrint("==SWToolKit==" + "----产品回调-----商品信息下----------")
            let proStr:String = pro.productIdentifier + "," + pro.localizedTitle + "," + pro.price.stringValue
            debugPrint("==SWToolKit==" + "----产品回调-----商品信息上----------")
            applePayLog.add(type: .product, title: "商品回调", des: "产品信息\(idx+1)(\(proStr))")
        }
        
        let pInfo = self.productDict[productId ?? ""]
        self.productClosure?(pInfo)
        self.cancelHandle()
    }
    
    func requestDidFinish(_ request: SKRequest) {
        debugPrint("==SWToolKit==" + "----产品回调-----请求结束----可能会多次回调------")
    }
    
    func request(_ request: SKRequest, didFailWithError error: any Error) {
        debugPrint("==SWToolKit==" + "----产品回调-----请求产品信息失败----------")
        applePayLog.add(type: .product, title: "商品回调", des: "获取产品信息失败\(error.localizedDescription)")
        self.productClosure?(nil)
        self.cancelHandle()
    }
    
    
}



