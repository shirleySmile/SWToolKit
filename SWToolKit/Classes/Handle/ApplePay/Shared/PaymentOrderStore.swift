//
//  PaymentOrderStore.swift
//  Pods
//
//  订单映射持久化（StoreKit 1 / StoreKit 2 两条链路共用）。
//  StoreKit 2：作为 appAccountToken（仅支持 UUID），回调时用它换回业务订单号；
//  StoreKit 1：写入 applicationUsername，回调原样带回后用它换回业务订单号。
//

import Foundation


/// 订单映射记录（会话Id → 订单号，附带创建时间用于过期清理）
private struct OrderRecord: Codable {
    let orderId: String
    let createdAt: Date
}


/// 订单映射存储。
/// 注意：不加 @MainActor，是因为它会在引擎的 nonisolated init 里创建；
/// 实际只在主线程访问（与引擎调用保持一致）。
final class PaymentOrderStore {

    /// 持久化存储 key（不能改，改了会丢失线上用户的订单映射）
    private static let orderMapKey = "SWToolKit.ApplePay.orderMap"

    /// 订单映射过期时间（Ask to Buy 无苹果超时上限，超时后清理避免堆积）
    private static let maxOrderAge: TimeInterval = 30 * 24 * 3600

    private var map: [UUID: OrderRecord] = [:]

    init() {
        self.map = Self.load()
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

    /// 保存订单映射到本地，并清理过期条目
    private func persist() {
        let deadline = Date().addingTimeInterval(-Self.maxOrderAge)
        var raw: [String: String] = [:]
        for (key, value) in self.map where value.createdAt >= deadline {
            if let data = try? JSONEncoder().encode(value),
               let json = String(data: data, encoding: .utf8) {
                raw[key.uuidString] = json
            }
        }
        UserDefaults.standard.set(raw, forKey: Self.orderMapKey)
    }

}
