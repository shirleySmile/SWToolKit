//
//  StoreKit2ReceiptRefreshService.swift
//  Pods
//
//  新版票据刷新：使用 AppStore.sync()，支持 iOS 15+。
//

import StoreKit
import Foundation


/// 使用 StoreKit 2 刷新本地票据
final class StoreKit2ReceiptRefreshService: ReceiptRefreshService {

    private var task: Task<Void, Never>?
    private var completion:((Error?)->Void)?

    override func startRefresh(completion:@escaping (Error?)->Void) {
        self.completion = completion
        self.task?.cancel()
        self.task = Task { @MainActor [weak self] in
            do {
                try await AppStore.sync()
                self?.finishRefresh(nil)
            } catch {
                self?.finishRefresh(error)
            }
        }
    }

    override func cancelRefresh() {
        self.task?.cancel()
        self.task = nil
        self.completion = nil
    }

    private func finishRefresh(_ error:Error?) {
        self.task = nil
        let completion = self.completion
        self.completion = nil
        completion?(error)
    }

}
