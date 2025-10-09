//
//  ApplyPayRefresh.swift
//  Pods
//
//  Created by admin on 2025/8/12.
//

import StoreKit


class ApplyPayRefresh:NSObject {
    
    private var callback:((Error?)->Void)?
    private var refreshRequest:SKReceiptRefreshRequest?
    private let timeout:Double = 20
    private weak var timer:Timer?
    
    /// 刷新本地票据
    func refreshLocalReceiptInfo(result:((Error?)->Void)?) {
        self.callback = result
        if self.refreshRequest != nil {
            return
        }
        self.refreshRequest = SKReceiptRefreshRequest()
        self.refreshRequest?.delegate = self
        self.refreshRequest?.start()
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false, block: { [weak self] timer in
            self?.timer?.invalidate()
            self?.timer = nil
            self?.timeoutHandle()
        })
    }
    
    func cancel(){
        self.refreshRequest?.delegate = nil
        self.refreshRequest?.cancel()
        self.refreshRequest = nil
    }
    
    private func timeoutHandle() {
        let error:NSError = .init(domain: "超时", code: 9521)
        self.callbackHandle(error)
    }

    private func callbackHandle(_ error:Error?) {
        self.timer?.invalidate()
        self.timer = nil
        self.refreshRequest?.delegate = nil
        self.refreshRequest?.cancel()
        self.refreshRequest = nil
        self.callback?(error)
        self.callback = nil
    }
    
}


//MARK: ---------------SKRequestDelegate-----------------
extension ApplyPayRefresh:SKRequestDelegate {
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        MessageInfo.print("-------请求失败-------\(error)")
        self.callbackHandle(error)
    }
    
    public func requestDidFinish(_ request: SKRequest) {
        MessageInfo.print("-------请求结束-------")
        self.callbackHandle(nil)
    }
    
}
