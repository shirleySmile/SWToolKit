//
//  ReceiptRefreshService.swift
//  Pods
//
//  Created by admin on 2025/8/12.
//

import StoreKit


/// 本地票据刷新
/// 两条链路共用：iOS 18+ 使用 AppStore.sync()，以下使用 SKReceiptRefreshRequest
class ReceiptRefreshService:NSObject {
    
    private var callback:((Error?)->Void)?
    /// iOS 18+ 的 AppStore.sync() 任务
    private var syncTask: Task<Void, Never>?
    /// iOS 18 以下的旧版票据刷新请求（iOS 18.0 起 SKReceiptRefreshRequest 已弃用）
    @available(iOS, deprecated: 18.0)
    private var refreshRequest:SKReceiptRefreshRequest?
    private let timeout:Double = 20
    private weak var timer:Timer?
    
    /// 刷新本地票据
    func refreshLocalReceiptInfo(result:((Error?)->Void)?) {
        self.callback = result
        if #available(iOS 18.0, *) {
            guard self.syncTask == nil else { return }
        } else {
            guard self.refreshRequest == nil else { return }
        }
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false, block: { [weak self] timer in
            self?.timer?.invalidate()
            self?.timer = nil
            self?.timeoutHandle()
        })
        if #available(iOS 18.0, *) {
            /// iOS 18.0 起 SKReceiptRefreshRequest 已弃用，改用 AppStore.sync() 与商店同步
            /// 注意：sync 语义偏交易同步（可能触发登录弹窗），与刷新票据文件非 1:1
            self.syncTask = Task { [weak self] in
                do {
                    try await AppStore.sync()
                    self?.callbackHandle(nil)
                } catch {
                    self?.callbackHandle(error)
                }
            }
        } else {
            // Fallback on earlier versions
            self.refreshRequest = SKReceiptRefreshRequest()
            self.refreshRequest?.delegate = self
            self.refreshRequest?.start()
        }
    }
    
    func cancel(){
        if #available(iOS 18.0, *) {
            self.syncTask?.cancel()
            self.syncTask = nil
        } else {
            self.refreshRequest?.delegate = nil
            self.refreshRequest?.cancel()
            self.refreshRequest = nil
        }
    }
    
    private func timeoutHandle() {
        let error:NSError = .init(domain: "超时", code: 9521)
        self.callbackHandle(error)
    }

    private func callbackHandle(_ error:Error?) {
        self.timer?.invalidate()
        self.timer = nil
        if #available(iOS 18.0, *) {
            self.syncTask?.cancel()
            self.syncTask = nil
        } else {
            self.refreshRequest?.delegate = nil
            self.refreshRequest?.cancel()
            self.refreshRequest = nil
        }
        self.callback?(error)
        self.callback = nil
    }
    
}


//MARK: ---------------SKRequestDelegate-----------------
/// 仅 iOS 18 以下走此代理回调（iOS 18+ 走 AppStore.sync()）
@available(iOS, deprecated: 18.0)
extension ReceiptRefreshService:SKRequestDelegate {
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        debugPrint("==SWToolKit==" + "-------请求失败-------\(error)")
        self.callbackHandle(error)
    }
    
    public func requestDidFinish(_ request: SKRequest) {
        debugPrint("==SWToolKit==" + "-------请求结束-------")
        self.callbackHandle(nil)
    }
    
}
