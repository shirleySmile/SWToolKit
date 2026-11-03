//
//  PaymentOrderStore.swift
//  Pods
//
//  订单映射持久化（StoreKit 1 / StoreKit 2 两条链路共用）。
//  StoreKit 2：作为 appAccountToken（仅支持 UUID），回调时用它换回业务订单号；
//  StoreKit 1：写入 applicationUsername，回调原样带回后用它换回业务订单号。
//
//  线程模型：
//  - 首次访问时才从本地加载；
//  - 增删改查都在内存里完成；
//  - 每次操作后异步写盘（专用串行队列，保证多次写盘按顺序落地）；
//  - App 即将终止时 `flush()` 做一次同步补写，避免最后一条映射丢失。
//

import Foundation
import UIKit


/// 订单映射记录（会话Id → 订单号，附带创建时间用于过期清理）
private struct OrderRecord: Codable {
    let orderId: String
    let createdAt: Date
}


/// 订单映射存储。
/// 不加 @MainActor：它会在引擎创建时构造，实际由调用方线程访问；
/// 内部状态只在调用方线程读写，写盘在自有的串行队列上执行。
final class PaymentOrderStore {

    /// 持久化存储 key（不能改，改了会丢失线上用户的订单映射）
    private static let orderMapKey = "SWToolKit.ApplePay.orderMap"

    /// 订单映射过期时间（Ask to Buy 无苹果超时上限，超时后清理避免堆积）
    private static let maxOrderAge: TimeInterval = 30 * 24 * 3600

    /// 写盘队列：串行，保证多次写盘按提交顺序落地
    private static let ioQueue = DispatchQueue(label: "com.swtoolkit.applepay.orderStore", qos: .utility)

    /// 首次访问时才加载本地数据
    private lazy var map: [UUID: OrderRecord] = Self.load()

    /// 保护待写盘快照（`flush` 可能在任何线程调用）
    private let snapshotLock = NSLock()
    /// 最近一次提交给写盘队列的快照，用于 App 终止时同步补写
    private var pendingSnapshot: [UUID: OrderRecord]?

    /// App 终止通知
    private var terminateObserver: NSObjectProtocol?

    init() {
        /// App 被系统终止时把最后一批数据同步写盘
        self.terminateObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.flush()
        }
    }

    deinit {
        if let terminateObserver {
            NotificationCenter.default.removeObserver(terminateObserver)
        }
    }

    /// 记录一笔待发货订单
    func insert(orderId: String, for sessionId: UUID) {
        self.map[sessionId] = OrderRecord(orderId: orderId, createdAt: Date())
        self.persist()
    }

    /// 仅查询订单号（不移除，用于失败回调上报）
    func orderId(for sessionId: UUID) -> String? {
        return self.map[sessionId]?.orderId
    }

    /// 取出并移除订单号
    func removeOrderId(for sessionId: UUID) -> String? {
        let orderId = self.map.removeValue(forKey: sessionId)?.orderId
        self.persist()
        return orderId
    }

    /// 仅移除映射
    func remove(for sessionId: UUID) {
        self.map.removeValue(forKey: sessionId)
        self.persist()
    }

    //MARK: ---------------持久化-----------------

    /// 提交一次异步写盘
    /// - Note: 快照必须在调用方线程取，后台不能直接读 `map`
    private func persist() {
        let snapshot = self.map
        self.snapshotLock.lock()
        self.pendingSnapshot = snapshot
        self.snapshotLock.unlock()
        Self.ioQueue.async {
            Self.writeToDisk(snapshot)
        }
    }

    /// 同步补写最近一次快照（App 即将终止时调用）
    /// - Note: 必须走同一个串行队列并 sync，保证排在之前排队的写盘之后，
    ///   否则先入队的旧快照可能在补写之后落地，反而把最新数据覆盖回旧值。
    func flush() {
        self.snapshotLock.lock()
        let snapshot = self.pendingSnapshot
        self.snapshotLock.unlock()
        guard let snapshot else { return }
        Self.ioQueue.sync {
            Self.writeToDisk(snapshot)
        }
    }

    /// 把快照编码后写入 UserDefaults（线程安全，可从任意队列调用）
    private static func writeToDisk(_ snapshot: [UUID: OrderRecord]) {
        let deadline = Date().addingTimeInterval(-maxOrderAge)
        var raw: [String: String] = [:]
        for (key, value) in snapshot where value.createdAt >= deadline {
            if let data = try? JSONEncoder().encode(value),
               let json = String(data: data, encoding: .utf8) {
                raw[key.uuidString] = json
            }
        }
        UserDefaults.standard.set(raw, forKey: orderMapKey)
    }

    /// 从本地恢复订单映射（会话Id → orderId），并清理过期条目
    private static func load() -> [UUID: OrderRecord] {
        guard let raw = UserDefaults.standard.dictionary(forKey: orderMapKey) as? [String: String] else { return [:] }
        let deadline = Date().addingTimeInterval(-maxOrderAge)
        var map: [UUID: OrderRecord] = [:]
        for (key, value) in raw {
            guard let sessionId = UUID(uuidString: key) else { continue }
            let record: OrderRecord?
            if let data = value.data(using: .utf8) {
                record = try? JSONDecoder().decode(OrderRecord.self, from: data)
            } else {
                record = nil
            }
            if let record {
                if record.createdAt >= deadline {
                    map[sessionId] = record
                }
            } else {
                // 兼容旧格式（value 直接为 orderId 字符串）
                let legacy = OrderRecord(orderId: value, createdAt: Date())
                if legacy.createdAt >= deadline {
                    map[sessionId] = legacy
                }
            }
        }
        return map
    }

}
