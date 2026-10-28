//
//  StoreKit1ReceiptRefreshService.swift
//  Pods
//
//  旧版票据刷新：使用 SKReceiptRefreshRequest（iOS 18.0 起弃用）。
//

import StoreKit
import Foundation


/// 使用 StoreKit 1 刷新本地票据
@available(iOS, deprecated: 18.0)
final class StoreKit1ReceiptRefreshService: ReceiptRefreshService {

    private var refreshRequest:SKReceiptRefreshRequest?
    private var completion:((Error?)->Void)?

    override func startRefresh(completion:@escaping (Error?)->Void) {
        self.completion = completion
        self.refreshRequest?.delegate = nil
        self.refreshRequest?.cancel()
        let request = SKReceiptRefreshRequest()
        request.delegate = self
        self.refreshRequest = request
        request.start()
    }

    override func cancelRefresh() {
        self.refreshRequest?.delegate = nil
        self.refreshRequest?.cancel()
        self.refreshRequest = nil
        self.completion = nil
    }

    private func finishRefresh(_ error:Error?) {
        self.runOnMain { [weak self] in
            guard let self else { return }
            self.refreshRequest?.delegate = nil
            self.refreshRequest = nil
            let completion = self.completion
            self.completion = nil
            completion?(error)
        }
    }

    private func runOnMain(_ block:@escaping ()->Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }

}


//MARK: ---------------SKRequestDelegate-----------------
extension StoreKit1ReceiptRefreshService:SKRequestDelegate {

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        debugPrint("==SWToolKit==" + "-------请求失败-------\(error)")
        self.finishRefresh(error)
    }

    public func requestDidFinish(_ request: SKRequest) {
        debugPrint("==SWToolKit==" + "-------请求结束-------")
        self.finishRefresh(nil)
    }

}
