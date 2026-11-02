//
//  IAPDemoSupport.swift
//  SWToolKit_Example
//
//  内购测试的辅助设施：日志、订单缓存、本地票据注入。
//  只用于 Example，不参与 pod 发布。
//

import Foundation
import StoreKit
import SWToolKit


/// Demo 日志：控制台 + 页面面板 + 导出文件
final class IAPDemoLog {

    static let shared = IAPDemoLog()

    private(set) var lines: [String] = []

    /// 面板刷新回调（都在主线程调用）
    var onChange: (() -> Void)?

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    private init() {}

    func add(_ text: String) {
        let line = "\(self.formatter.string(from: Date())) \(text)"
        self.lines.append(line)
        /// 面板不做无限增长
        if self.lines.count > 800 {
            self.lines.removeFirst(self.lines.count - 600)
        }
        print("==IAPDemo== \(line)")
        self.onChange?()
    }

    func clear() {
        self.lines.removeAll()
        self.onChange?()
    }

    /// 导出到沙盒 Documents，返回文件 URL
    func export() -> URL? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let name = "IAPDemo_\(Int(Date().timeIntervalSince1970)).log"
        let url = dir.appendingPathComponent(name)
        do {
            try self.lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

}


/// 订单记录（对应 MW_OrderInfo）
struct IAPDemoOrder: Codable {
    let orderId: String
    let productId: String
    let createdAt: String
}


/// 本地订单缓存（对应 MW 的 saveServiceOrder / getOrderInfo）
final class IAPDemoOrderStore {

    private static let storageKey = "IAPDemo.orders"

    /// pod 内部的订单映射 key：清空本地订单时一起清，
    /// 否则迟到回调还能从 pod 里反查出旧订单号，测试结果会失真
    private static let podOrderMapKey = "SWToolKit.ApplePay.orderMap"

    func all() -> [String: IAPDemoOrder] {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let map = try? JSONDecoder().decode([String: IAPDemoOrder].self, from: data) else {
            return [:]
        }
        return map
    }

    func count() -> Int {
        return self.all().count
    }

    func save(_ order: IAPDemoOrder) {
        var map = self.all()
        map[order.orderId] = order
        self.persist(map)
    }

    func removeAll() {
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
        UserDefaults.standard.removeObject(forKey: Self.podOrderMapKey)
    }

    private func persist(_ map: [String: IAPDemoOrder]) {
        guard let data = try? JSONEncoder().encode(map) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

}


/// 本地票据注入：直接读写 Bundle.main.appStoreReceiptURL 指向的文件。
/// 只用来模拟「有票据 / 无票据」两条分支，内容不是真实苹果票据。
enum IAPDemoReceipt {

    static var url: URL? {
        return Bundle.main.appStoreReceiptURL
    }

    static func status() -> String {
        guard let url = self.url else { return "appStoreReceiptURL 为空" }
        guard FileManager.default.fileExists(atPath: url.path) else { return "无票据" }
        let size = (try? Data(contentsOf: url).count) ?? 0
        return "有票据（\(size) 字节）"
    }

    /// 预置一份假票据，让发货链路能走成功分支
    @discardableResult
    static func installFake() -> String {
        guard let url = self.url else { return "失败：appStoreReceiptURL 为空" }
        let dir = url.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = Data("iap-demo-fake-receipt-\(UUID().uuidString)".utf8)
            try data.write(to: url, options: .atomic)
            return "已写入假票据（\(data.count) 字节）"
        } catch {
            return "写入失败：\(error.localizedDescription)"
        }
    }

    /// 删除本地票据，复现「购买成功但读不到票据」
    @discardableResult
    static func remove() -> String {
        guard let url = self.url else { return "失败：appStoreReceiptURL 为空" }
        guard FileManager.default.fileExists(atPath: url.path) else { return "本来就没有票据" }
        do {
            try FileManager.default.removeItem(at: url)
            return "已删除本地票据"
        } catch {
            return "删除失败：\(error.localizedDescription)"
        }
    }

}


/// 商品类型分组：订阅包含自动续期与非续期
enum IAPDemoProductGroup: Int, CaseIterable {
    case nonConsumable
    case consumable
    case subscription

    var title: String {
        switch self {
        case .nonConsumable: return "非消耗型"
        case .consumable:    return "消耗型"
        case .subscription:  return "订阅"
        }
    }

    /// Product.ProductType 是结构体（不是枚举），只能逐个比较
    static func group(for type: Product.ProductType) -> IAPDemoProductGroup {
        if type == .consumable { return .consumable }
        if type == .nonConsumable { return .nonConsumable }
        return .subscription
    }
}


/// StoreKit 拉回来的商品，只用于展示和选择
struct IAPDemoProduct {
    let id: String
    let name: String
    let priceText: String
    let group: IAPDemoProductGroup
}


/// Demo 商品与默认参数
enum IAPDemoConfig {

    static let nonConsumable = "mw_900002"
    static let consumable = "mw_900001"
    static let subscription = "mw_100001"

    /// 默认商品 ID：本地 .storekit 与真实沙盒使用同一套 ID
    static let defaultProductIds = [nonConsumable, consumable, subscription]

    static let defaultTimeout: Double = 20.0

    /// 每次启动固定使用的实现模式（不再按系统版本切换）
    static let engineMode: ApplePayManager.ImplementationMode = .legacy
    static let receiptRefreshMode: ApplePayManager.ImplementationMode = .legacy

    static let delegateEnabledKey = "IAPDemo.delegateEnabled"
    /// v2：避免旧安装里持久化的 demo_* ID 盖住新默认值
    static let productIdsKey = "IAPDemo.productIds.v2"
    static let promoSimulationKey = "IAPDemo.promoSimulation"

    /// 兼容中英文逗号、分号、空格、换行，去空去重
    static func parseProductIds(_ raw: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",，;； \t\r\n")
        var seen = Set<String>()
        var result: [String] = []
        for part in raw.components(separatedBy: separators) {
            let id = part.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !id.isEmpty, !seen.contains(id) else { continue }
            seen.insert(id)
            result.append(id)
        }
        return result
    }

}
