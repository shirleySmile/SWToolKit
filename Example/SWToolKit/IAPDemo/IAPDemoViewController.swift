//
//  IAPDemoViewController.swift
//  SWToolKit_Example
//
//  内购测试页：入口在首页「内购测试」按钮。
//  只用于 Example，不参与 pod 发布。
//

import UIKit
import SWToolKit


final class IAPDemoViewController: UIViewController {

    private let host = IAPDemoHost.shared

    private let statusLabel = UILabel()
    private let productSegment = UISegmentedControl(items: ["非消耗型", "消耗型", "订阅"])
    private let orderField = UITextField()
    private let timeoutField = UITextField()
    private let mockSegment = UISegmentedControl(items: IAPDemoHost.MockMode.allCases.map { $0.title })
    private let delegateSwitch = UISwitch()
    private let promoSwitch = UISwitch()
    private let logView = UITextView()

    private var products: [String] {
        return [IAPDemoConfig.nonConsumable, IAPDemoConfig.consumable, IAPDemoConfig.subscription]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "内购测试"
        self.view.backgroundColor = .white
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "关闭", style: .plain, target: self, action: #selector(close))

        self.setupUI()
        self.setupValues()

        IAPDemoLog.shared.onChange = { [weak self] in
            self?.reloadLog()
        }

        self.host.applyDelegateSetting()
        self.host.setTimeout(IAPDemoConfig.defaultTimeout)
        self.reloadLog()
        self.host.checkLocalProducts()
    }

    // MARK: - UI

    private func setupUI() {
        let scrollView = UIScrollView()
        scrollView.keyboardDismissMode = .onDrag
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(scrollView)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -12),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -24),
        ])

        self.statusLabel.numberOfLines = 0
        self.statusLabel.font = .systemFont(ofSize: 12)
        self.statusLabel.textColor = .darkGray
        stack.addArrangedSubview(self.statusLabel)

        stack.addArrangedSubview(self.caption("商品（.storekit 本地配置）"))
        stack.addArrangedSubview(self.productSegment)

        self.orderField.borderStyle = .roundedRect
        self.orderField.font = .systemFont(ofSize: 13)
        self.orderField.autocorrectionType = .no
        self.orderField.autocapitalizationType = .none
        stack.addArrangedSubview(self.caption("订单号（pay 时传入）"))
        stack.addArrangedSubview(self.row([self.orderField, self.button("换一个", #selector(tapRandomOrder))]))

        self.timeoutField.borderStyle = .roundedRect
        self.timeoutField.font = .systemFont(ofSize: 13)
        self.timeoutField.keyboardType = .decimalPad
        stack.addArrangedSubview(self.caption("超时阈值（秒）"))
        stack.addArrangedSubview(self.row([self.timeoutField, self.button("应用", #selector(tapApplyTimeout))]))

        stack.addArrangedSubview(self.row([
            self.button("购买", #selector(tapBuy)),
            self.button("恢复购买", #selector(tapRestore)),
        ]))

        stack.addArrangedSubview(self.row([
            self.button("刷新票据", #selector(tapRefreshReceipt)),
            self.button("读取票据", #selector(tapReadReceipt)),
        ]))

        stack.addArrangedSubview(self.row([
            self.button("预置票据", #selector(tapInstallReceipt)),
            self.button("删除票据", #selector(tapRemoveReceipt)),
        ]))

        stack.addArrangedSubview(self.row([
            self.button("清空订单映射", #selector(tapClearOrders)),
            self.button("启动检测", #selector(tapLaunchCheck)),
        ]))

        self.delegateSwitch.addTarget(self, action: #selector(tapDelegateSwitch), for: .valueChanged)
        stack.addArrangedSubview(self.switchRow("挂载 delegate（关 = 测无法投递）", self.delegateSwitch))

        self.promoSwitch.addTarget(self, action: #selector(tapPromoSwitch), for: .valueChanged)
        stack.addArrangedSubview(self.switchRow("允许促销购买（shouldAddStorePayment）", self.promoSwitch))

        self.mockSegment.selectedSegmentIndex = IAPDemoHost.MockMode.success.rawValue
        self.mockSegment.addTarget(self, action: #selector(tapMockMode), for: .valueChanged)
        stack.addArrangedSubview(self.caption("模拟后台校验"))
        stack.addArrangedSubview(self.mockSegment)

        stack.addArrangedSubview(self.row([
            self.button("模拟促销交易(SK1)", #selector(tapPromo)),
            self.button("加载商品", #selector(tapLoadProducts)),
        ]))

        stack.addArrangedSubview(self.caption("日志"))
        self.logView.isEditable = false
        self.logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        self.logView.backgroundColor = .black
        self.logView.textColor = .green
        self.logView.layer.cornerRadius = 6
        self.logView.textContainerInset = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        self.logView.heightAnchor.constraint(equalToConstant: 260).isActive = true
        stack.addArrangedSubview(self.logView)

        stack.addArrangedSubview(self.row([
            self.button("打印 pod 日志", #selector(tapPodLog)),
            self.button("清空日志", #selector(tapClearLog)),
            self.button("导出日志", #selector(tapExportLog)),
        ]))

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }

    private func setupValues() {
        self.orderField.text = self.host.currentOrder?.orderId ?? self.newOrderId()
        self.timeoutField.text = String(Int(IAPDemoConfig.defaultTimeout))
        self.delegateSwitch.isOn = self.host.delegateEnabled
        self.promoSwitch.isOn = self.host.allowPromotedPurchase
    }

    private func caption(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12)
        label.textColor = .gray
        return label
    }

    private func row(_ views: [UIView]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }

    private func switchRow(_ text: String, _ toggle: UISwitch) -> UIStackView {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12)
        label.numberOfLines = 0
        let stack = UIStackView(arrangedSubviews: [label, toggle])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }

    private func button(_ title: String, _ action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13)
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.layer.cornerRadius = 6
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: - 状态

    private func reloadLog() {
        let lines = IAPDemoLog.shared.lines
        self.logView.text = lines.joined(separator: "\n")
        if !self.logView.text.isEmpty {
            let range = NSRange(location: (self.logView.text as NSString).length, length: 0)
            self.logView.scrollRangeToVisible(range)
        }
        self.refreshStatus()
    }

    private func refreshStatus() {
        let state = self.host.state.rawValue
        let delegate = self.host.isDelegateConnected ? "已挂载" : "未挂载"
        let orders = self.host.orderStore.count()
        let timeout = Int(ApplePayManager.share.timeoutInterval)
        self.statusLabel.text = "状态：\(state)    delegate：\(delegate)\n票据：\(IAPDemoReceipt.status())    本地订单：\(orders) 条    超时：\(timeout)s"
    }

    private func newOrderId() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        return "demo-\(formatter.string(from: Date()))"
    }

    private var selectedProductId: String {
        let index = max(0, min(self.productSegment.selectedSegmentIndex, self.products.count - 1))
        return self.products[index]
    }

    private func currentOrderId() -> String {
        let value = (self.orderField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty {
            let generated = self.newOrderId()
            self.orderField.text = generated
            return generated
        }
        return value
    }

    private func appliedTimeout() -> Double {
        let value = Double(self.timeoutField.text ?? "") ?? IAPDemoConfig.defaultTimeout
        return max(1, value)
    }

    // MARK: - Actions

    @objc private func close() {
        self.dismiss(animated: true)
    }

    @objc private func dismissKeyboard() {
        self.view.endEditing(true)
    }

    @objc private func tapRandomOrder() {
        self.orderField.text = self.newOrderId()
        self.refreshStatus()
    }

    @objc private func tapApplyTimeout() {
        self.host.setTimeout(self.appliedTimeout())
        self.refreshStatus()
    }

    @objc private func tapBuy() {
        self.host.setTimeout(self.appliedTimeout())
        self.host.buy(productId: self.selectedProductId, orderId: self.currentOrderId())
        self.refreshStatus()
    }

    @objc private func tapRestore() {
        self.host.setTimeout(self.appliedTimeout())
        self.host.restore()
        self.refreshStatus()
    }

    @objc private func tapRefreshReceipt() {
        self.host.refreshReceipt()
    }

    @objc private func tapReadReceipt() {
        self.host.readReceipt()
    }

    @objc private func tapInstallReceipt() {
        IAPDemoLog.shared.add("预置票据：\(IAPDemoReceipt.installFake())")
        self.refreshStatus()
    }

    @objc private func tapRemoveReceipt() {
        IAPDemoLog.shared.add("删除票据：\(IAPDemoReceipt.remove())")
        self.refreshStatus()
    }

    @objc private func tapClearOrders() {
        self.host.orderStore.removeAll()
        IAPDemoLog.shared.add("已清空本地订单与 pod 订单映射")
        self.refreshStatus()
    }

    @objc private func tapLaunchCheck() {
        self.host.launchCheck()
        self.refreshStatus()
    }

    @objc private func tapDelegateSwitch() {
        self.host.delegateEnabled = self.delegateSwitch.isOn
        self.host.applyDelegateSetting()
        self.refreshStatus()
    }

    @objc private func tapPromoSwitch() {
        self.host.allowPromotedPurchase = self.promoSwitch.isOn
        IAPDemoLog.shared.add("shouldAddStorePayment 将返回 \(self.promoSwitch.isOn)")
    }

    @objc private func tapMockMode() {
        let index = self.mockSegment.selectedSegmentIndex
        self.host.mockMode = IAPDemoHost.MockMode(rawValue: index) ?? .success
        IAPDemoLog.shared.add("模拟后台校验：\(self.host.mockMode.title)")
    }

    @objc private func tapPromo() {
        self.host.simulatePromotedPurchase(productId: self.selectedProductId)
    }

    @objc private func tapLoadProducts() {
        self.host.checkLocalProducts()
    }

    @objc private func tapPodLog() {
        self.host.dumpPodLog()
    }

    @objc private func tapClearLog() {
        IAPDemoLog.shared.clear()
    }

    @objc private func tapExportLog() {
        guard let url = IAPDemoLog.shared.export() else {
            IAPDemoLog.shared.add("导出日志失败")
            return
        }
        IAPDemoLog.shared.add("日志已导出：\(url.path)")
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = self.view
        activity.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY - 60, width: 1, height: 1)
        self.present(activity, animated: true)
    }

}
