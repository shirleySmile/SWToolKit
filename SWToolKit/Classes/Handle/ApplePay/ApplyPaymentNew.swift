//
//  ApplyPaymentNew.swift
//  Pods
//
//  Created by muwa on 2025/10/27.
//

import StoreKit
import Foundation


@available(iOS 15.0, *)
// 定义一个主类来管理内购相关逻辑
@MainActor
private final class ApplyPaymentNew {
    
    // 发布产品列表，供UI监听
    @Published private(set) var products: [Product] = []
    // 发布当前有效的交易，用于解锁内容
    @Published private(set) var activeTransactions: Set<StoreKit.Transaction> = []
    
    // 初始化时开始监听交易更新
    init() {
        Task {
            await listenForTransactionUpdates()
        }
    }
    
    // 1. 从App Store获取产品信息
    func fetchProducts() async {
        do {
            // 这里的字符串数组对应你在App Store Connect设置的产品ID
            let productIds = ["com.yourapp.consumable.coin", "com.yourapp.premium.membership"]
            products = try await Product.products(for: productIds)
        } catch {
            print("Failed to fetch products: \(error)")
            products = []
        }
    }
    
    // 2. 发起购买
    func purchase(_ product: Product) async throws {
        // 调用购买接口
        let result = try await product.purchase()
        
        switch result {
            case .success(let verificationResult):
                // 购买成功，需要对交易凭证进行验证
                if let transaction = try? verificationResult.payloadValue {
                    // 验证通过，解锁用户购买的内容或服务
                    await unlockPurchasedContent(for: transaction)
                    // 完成交易，告诉App Store此次购买已处理完毕
                    await transaction.finish()
                }
            case .userCancelled:
                // 用户取消了购买
                break
            case .pending:
                // 交易挂起，可能需要家长同意等
                break
            @unknown default:
                break
        }
    }
    
    
    
    // 3. 处理交易结果并更新应用状态
    private func unlockPurchasedContent(for transaction: StoreKit.Transaction) async {
        // 将交易存入活跃交易集合，UI可以据此更新
        activeTransactions.insert(transaction)
        // 这里可以根据transaction.productID来判断具体购买的是哪个商品，然后解锁对应的功能。
        // 例如，将购买状态持久化到UserDefaults或你的服务器。
    }
    
    
    
    // 4. 监听交易更新（非常重要！用于处理例如应用在购买过程中被挂起后恢复的场景）
    private func listenForTransactionUpdates() async {
        for await update in Transaction.updates {
            // 同样需要验证交易
            if let transaction = try? update.payloadValue {
                await unlockPurchasedContent(for: transaction)
                await transaction.finish()
            }
        }
    }
    
    
    // 5. 恢复购买（针对非消耗型商品和订阅）
    func restorePurchases() async throws {
        // 遍历用户当前的所有权益（即已购买且未退款的有效非消耗型商品和订阅）
        for await verificationResult in Transaction.currentEntitlements {
            if let transaction = try? verificationResult.payloadValue {
                await unlockPurchasedContent(for: transaction)
            }
        }
    }
    
}


