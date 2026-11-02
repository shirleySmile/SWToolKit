//
//  ReceiptRefreshService.swift
//  Pods
//
//  本地票据刷新基类。
//  对外只使用 refreshLocalReceiptInfo / cancel；
//  子类只负责实现具体刷新方式（StoreKit 1 / StoreKit 2）。
//

import Foundation


/// 本地票据刷新基类
///
/// 负责超时、回调一次性保护、取消清理；
/// 具体刷新动作由子类实现。
class ReceiptRefreshService:NSObject {

    private var callback:((Error?)->Void)?
    private var timer:Timer?
    private var isRefreshing = false
    private let timeout:Double = 20

    /// 刷新本地票据
    /// - Parameter result: 刷新结果；成功为 nil，失败或超时返回错误
    /// - Note: 同一时间只支持一次刷新，20 秒超时，回调只会执行一次
    final func refreshLocalReceiptInfo(result:((Error?)->Void)?) {
        self.callback = result
        guard self.isRefreshing == false else { return }
        self.isRefreshing = true
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false, block: { [weak self] timer in
            timer.invalidate()
            self?.finish(NSError(domain: "超时", code: 9521))
        })
        self.startRefresh { [weak self] error in
            self?.finish(error)
        }
    }

    /// 取消当前刷新
    /// - Note: 取消不会触发 result 回调
    final func cancel() {
        self.timer?.invalidate()
        self.timer = nil
        self.callback = nil
        self.isRefreshing = false
        self.cancelRefresh()
    }

    // MARK: - 子类实现

    /// 开始具体刷新，完成后调用 completion
    func startRefresh(completion:@escaping (Error?)->Void) {
        fatalError("子类必须实现 startRefresh(completion:)")
    }

    /// 取消具体刷新
    func cancelRefresh() {
        fatalError("子类必须实现 cancelRefresh()")
    }

    // MARK: - 内部

    private func finish(_ error:Error?) {
        guard self.isRefreshing else { return }
        self.isRefreshing = false
        self.timer?.invalidate()
        self.timer = nil
        self.cancelRefresh()
        let callback = self.callback
        self.callback = nil
        callback?(error)
    }

}
