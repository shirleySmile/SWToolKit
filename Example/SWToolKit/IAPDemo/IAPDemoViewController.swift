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
    private let productIdField = UITextField()
    private let productStateLabel = UILabel()
    private let productStack = UIStackView()
    private let selectedProductLabel = UILabel()
    private let orderField = UITextField()
    private let timeoutField = UITextField()
    private let mockSegment = UISegmentedControl(items: IAPDemoHost.MockMode.allCases.map { $0.title })
    private let delegateSwitch = UISwitch()
    private let promoSwitch = UISwitch()
    private let promoSimulationSwitch = UISwitch()
    private let logView = UITextView()

    /// 当前选中的商品
    private var selectedProductId: String?
    /// 模拟促销交易按钮行（调试开关关闭时隐藏）
    private var promoButtonRow: UIStackView?

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

        self.host.onProductsChanged = { [weak self] in
            self?.renderProducts()
        }

        self.reloadLog()
        self.host.refreshProducts()
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

        stack.addArrangedSubview(self.caption("商品（StoreKit 直连，本地 .storekit 生效时取本地）"))

        self.productIdField.borderStyle = .roundedRect
        self.productIdField.font = .systemFont(ofSize: 12)
        self.productIdField.autocorrectionType = .no
        self.productIdField.autocapitalizationType = .none
        self.productIdField.placeholder = "逗号分隔的 productId"
        let refreshButton = self.button("刷新", #selector(tapRefreshProducts))
        let idRow = UIStackView(arrangedSubviews: [self.productIdField, refreshButton])
        idRow.axis = .horizontal
        idRow.spacing = 8
        idRow.alignment = .fill
        refreshButton.setContentHuggingPriority(.required, for: .horizontal)
        refreshButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        refreshButton.widthAnchor.constraint(equalToConstant: 84).isActive = true
        stack.addArrangedSubview(idRow)

        self.productStateLabel.numberOfLines = 0
        self.productStateLabel.font = .systemFont(ofSize: 11)
        self.productStateLabel.textColor = .gray
        stack.addArrangedSubview(self.productStateLabel)

        self.productStack.axis = .vertical
        self.productStack.spacing = 6
        stack.addArrangedSubview(self.productStack)

        self.selectedProductLabel.font = .systemFont(ofSize: 12)
        self.selectedProductLabel.textColor = .darkGray
        self.selectedProductLabel.numberOfLines = 0
        stack.addArrangedSubview(self.selectedProductLabel)

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

        // TODO: 内购测试专用：模拟促销交易，全部测试完成后删除下面这个开关和按钮
        self.promoSimulationSwitch.addTarget(self, action: #selector(tapPromoSimulationSwitch), for: .valueChanged)
        stack.addArrangedSubview(self.switchRow("调试：模拟促销交易（测试后删除）", self.promoSimulationSwitch))

        let promoRow = self.row([self.button("模拟促销交易(SK1)", #selector(tapPromo))])
        promoRow.isHidden = !self.host.promoSimulationEnabled
        self.promoButtonRow = promoRow
        stack.addArrangedSubview(promoRow)

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
        self.productIdField.text = self.host.storedProductIds.joined(separator: ",")
        self.orderField.text = self.host.currentOrder?.orderId ?? self.newOrderId()
        self.timeoutField.text = String(Int(IAPDemoConfig.defaultTimeout))
        self.delegateSwitch.isOn = self.host.delegateEnabled
        self.promoSwitch.isOn = self.host.allowPromotedPurchase
        self.promoSimulationSwitch.isOn = self.host.promoSimulationEnabled
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

    // MARK: - 商品列表

    private func renderProducts() {
        self.productStack.arrangedSubviews.forEach {
            self.productStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        switch self.host.productLoadState {
        case .idle:
            self.productStateLabel.text = ""
            self.productStateLabel.textColor = .gray
        case .loading:
            self.productStateLabel.text = "正在加载商品…"
            self.productStateLabel.textColor = .gray
        case .failed(let message):
            self.productStateLabel.text = "加载失败：\(message)"
            self.productStateLabel.textColor = .systemRed
        case .loaded:
            if self.host.products.isEmpty {
                self.productStateLabel.text = "未获取到商品。当前环境可能没有这些商品 ID（本地 .storekit 未生效或 App Store Connect 未配置）"
                self.productStateLabel.textColor = .systemOrange
            } else {
                let groupTitles = IAPDemoProductGroup.allCases
                    .filter { group in self.host.products.contains { $0.group == group } }
                    .map { $0.title }
                self.productStateLabel.text = "共 \(self.host.products.count) 个商品：\(groupTitles.joined(separator: " / "))"
                self.productStateLabel.textColor = .gray
            }
        }

        // 选中项失效（换了一批 ID）时自动选第一个
        if let selected = self.selectedProductId,
           !self.host.products.contains(where: { $0.id == selected }) {
            self.selectedProductId = nil
        }
        if self.selectedProductId == nil {
            self.selectedProductId = self.host.products.first?.id
        }

        for group in IAPDemoProductGroup.allCases {
            let items = self.host.products.filter { $0.group == group }
            guard !items.isEmpty else { continue }

            let header = UILabel()
            header.text = "\(group.title)（\(items.count)）"
            header.font = .systemFont(ofSize: 12, weight: .semibold)
            header.textColor = .secondaryLabel
            self.productStack.addArrangedSubview(header)

            for item in items {
                self.productStack.addArrangedSubview(self.productRow(item))
            }
        }

        self.updateSelectedProductLabel()
    }

    private func productRow(_ product: IAPDemoProduct) -> UIButton {
        let isSelected = product.id == self.selectedProductId
        var config = isSelected ? UIButton.Configuration.tinted() : UIButton.Configuration.gray()
        config.title = product.name
        config.subtitle = "\(product.id) · \(product.priceText)"
        config.titleAlignment = .leading
        config.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        config.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 11)
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .fill
        button.addAction(UIAction { [weak self] _ in
            self?.selectProduct(product.id)
        }, for: .touchUpInside)
        return button
    }

    private func selectProduct(_ id: String) {
        self.selectedProductId = id
        self.renderProducts()
        if let product = self.host.products.first(where: { $0.id == id }) {
            IAPDemoLog.shared.add("已选择商品：\(product.id) [\(product.group.title)]")
        }
    }

    private func updateSelectedProductLabel() {
        guard let id = self.selectedProductId,
              let product = self.host.products.first(where: { $0.id == id }) else {
            self.selectedProductLabel.text = "已选商品：未选择"
            self.selectedProductLabel.textColor = .systemOrange
            return
        }
        self.selectedProductLabel.text = "已选商品：\(product.name) [\(product.group.title)] \(product.id) \(product.priceText)"
        self.selectedProductLabel.textColor = .darkGray
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
        guard let productId = self.selectedProductId else {
            IAPDemoLog.shared.add("请先选择商品")
            return
        }
        self.host.buy(productId: productId, orderId: self.currentOrderId())
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
        guard let productId = self.selectedProductId else {
            IAPDemoLog.shared.add("请先选择商品")
            return
        }
        self.host.simulatePromotedPurchase(productId: productId)
    }

    // TODO: 内购测试专用：模拟促销交易，全部测试完成后删除该方法
    @objc private func tapPromoSimulationSwitch() {
        self.host.promoSimulationEnabled = self.promoSimulationSwitch.isOn
        self.promoButtonRow?.isHidden = !self.promoSimulationSwitch.isOn
        IAPDemoLog.shared.add("模拟促销交易开关：\(self.promoSimulationSwitch.isOn ? "开" : "关")")
    }

    @objc private func tapRefreshProducts() {
        let ids = IAPDemoConfig.parseProductIds(self.productIdField.text ?? "")
        self.host.storedProductIds = ids
        self.view.endEditing(true)
        self.host.refreshProducts(ids: ids)
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
