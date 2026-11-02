//
//  ViewController.swift
//  SWToolKit
//
//  Created by shirley on 07/24/2025.
//

import UIKit
import SWToolKit


class ViewController: UIViewController {

    /// 自动打开内购测试页只做一次（关闭后 viewDidAppear 会再次触发）
    private var didAutoOpenIAPDemo = false
    /// 自动打开旋转测试页只做一次
    private var didAutoOpenRotationTest = false

    override func viewDidLoad() {
        super.viewDidLoad()
       
        let title = UILabel(frame: .init(x: 0, y: 200, width: self.view.frame.width, height: 20))
        title.text = "这是一个工具库"
        title.textAlignment = .center
        self.view.addSubview(title)
        
        self.showNaviView(showBack: true)
        self.navBar.backgroundColor = .yellow
        
        let textF1:UITextField = .init(frame: CGRect(x: 30, y: kNaviH + 100, width: 100, height: 40))
        textF1.backgroundColor = .red.withAlphaComponent(0.2)
        self.view.addSubview(textF1)
        
        let textF2:UITextField = .init(frame: CGRect(x: 30, y: textF1.maxY + 50, width: 100, height: 40))
        textF2.backgroundColor = .red.withAlphaComponent(0.2)
        self.view.addSubview(textF2)

        KeyboardTool.addKBNotification(self, showToolView: true)
        
        let fmt:String = "yyyy-MM-dd HH:mm:ss"
        let dateStr = "2025-08-28 23:50:10"
        let date:Date = Date.date(format: fmt, str: dateStr)
        print("==123==", date.isToday)
        
        
        let btn = UIButton(type: .custom)
        btn.frame = .init(x: 20, y: 400, width: 100, height: 20)
        btn.setTitle("显示弹窗1", for: .normal)
        btn.setTitleColor(.red, for: .normal)
        self.view.addSubview(btn)
        btn.addTarget(self, action: #selector(click1), for: .touchUpInside)
        
        
        let btn2 = UIButton(type: .custom)
        btn2.frame = .init(x: 20, y: 500, width: 100, height: 20)
        btn2.setTitle("显示弹窗2", for: .normal)
        btn2.setTitleColor(.red, for: .normal)
        self.view.addSubview(btn2)
        btn2.addTarget(self, action: #selector(click2), for: .touchUpInside)
        
        let btn3 = UIButton(type: .custom)
        btn3.frame = .init(x: 280, y: 400, width: 100, height: 20)
        btn3.setTitle("显示弹窗3", for: .normal)
        btn3.setTitleColor(.red, for: .normal)
        self.view.addSubview(btn3)
        btn3.addTarget(self, action: #selector(click3), for: .touchUpInside)
        
        let btn100 = UIButton(type: .custom)
        btn100.frame = .init(x: 280, y: 500, width: 100, height: 20)
        btn100.setTitle("测试导航栏 vc", for: .normal)
        btn100.setTitleColor(.red, for: .normal)
        self.view.addSubview(btn100)
        btn100.addTarget(self, action: #selector(click100), for: .touchUpInside)
        
        let btn4 = UIButton(type: .custom)
        btn4.frame = .init(x: 20, y: 560, width: 100, height: 20)
        btn4.setTitle("内购测试", for: .normal)
        btn4.setTitleColor(.blue, for: .normal)
        self.view.addSubview(btn4)
        btn4.addTarget(self, action: #selector(clickIAPDemo), for: .touchUpInside)

        let btn5 = UIButton(type: .custom)
        btn5.frame = .init(x: 20, y: 620, width: 100, height: 20)
        btn5.setTitle("旋转测试", for: .normal)
        btn5.setTitleColor(.systemGreen, for: .normal)
        self.view.addSubview(btn5)
        btn5.addTarget(self, action: #selector(clickRotationTest), for: .touchUpInside)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /// 自动化调试用：Xcode 里给 Scheme 加启动参数 -IAPDemoAutoOpen 可直接进内购测试页
        if ProcessInfo.processInfo.arguments.contains("-IAPDemoAutoOpen"),
           !self.didAutoOpenIAPDemo,
           self.presentedViewController == nil {
            self.didAutoOpenIAPDemo = true
            self.clickIAPDemo()
        }
        /// 自动化调试用：加启动参数 -RotationTestAutoOpen 可直接进旋转测试
        if ProcessInfo.processInfo.arguments.contains("-RotationTestAutoOpen"),
           !self.didAutoOpenRotationTest {
            self.didAutoOpenRotationTest = true
            self.clickRotationTest()
        }
    }
    
    
    @objc func click1(){
        AlertView.show()
    }

    
    @objc func click2(){
        let view = TopPopupDemoView(frame: .init(x: 0, y: 0, width: kScreen.width, height: 200))
        view.screenPopupShow(options: .init(animation: .enterFromTop()))
    }
    
    @objc func click3() {
        let vc = ScreenViewController()
        self.present(vc, animated: true)
    }

    @objc func clickRotationTest() {
        let view = RotationTestView(frame: .init(x: 0, y: 0, width: kScreen.width, height: 420))
        view.animationShow(header: .init(view: SheetBorderSliderHeader(viewHeight: 40), type: .vertical),
                           cornerSize: .init(width: 16, height: 16))
    }
    
    @objc func clickIAPDemo() {
        let vc = IAPDemoViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true)
    }
    
    @objc func click100() {
        let vc = NaviController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

/// 顶部弹窗（click2）：演示新入口 + 内容跟随容器宽度重排
class TopPopupDemoView: UIView, ScreenPopupDelegate {

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .red.withAlphaComponent(0.7)

        label.numberOfLines = 0
        label.textColor = .white
        label.font = .systemFont(ofSize: 15)
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            label.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            label.rightAnchor.constraint(equalTo: rightAnchor, constant: -16)
        ])
        self.updateLabel(size: frame.size, container: CGSize(width: kScreen.width, height: kScreen.height))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateLabel(size: CGSize, container: CGSize) {
        label.text = "顶部弹窗（.enterFromTop）\n自身：\(Int(size.width)) x \(Int(size.height))\n容器：\(Int(container.width)) x \(Int(container.height))\n\n旋转后宽度应跟随容器，文字跟着重排"
    }

    // MARK: ScreenPopupDelegate

    func screenPopupDidChange(_ change: ScreenPopupLayoutChange) {
        self.updateLabel(size: change.frame.size, container: change.containerSize)
    }

    func screenPopupDidShow() {
        self.updateLabel(size: frame.size, container: CGSize(width: kScreen.width, height: kScreen.height))
    }
}

class AlertView:UIView, ScreenPopupDelegate {
    
    static func show() {
        
        let view = AlertView(frame: .init(origin: .zero, size: .init(width: kScreen.width, height: 300)))
        view.animationShow(header: .init(view: SheetBorderSliderHeader.init(viewHeight: 60), type: .cover))
    }

    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let sizeLabel = UILabel()
    private let closeButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.setupUI()
        self.updateSizeLabel(size: frame.size, container: CGSize(width: kScreen.width, height: kScreen.height))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        titleLabel.text = "这是 AlertView（sheet）"
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.numberOfLines = 0

        detailLabel.text = "覆盖式头部下面是内容区，旋转或 iPad 分屏后宽度跟随容器，内部 Auto Layout 会重排。"
        detailLabel.font = .systemFont(ofSize: 14)
        detailLabel.textColor = .darkGray
        detailLabel.numberOfLines = 0

        sizeLabel.font = .systemFont(ofSize: 13)
        sizeLabel.textColor = .gray
        sizeLabel.numberOfLines = 0

        closeButton.setTitle("关闭", for: .normal)
        closeButton.contentHorizontalAlignment = .left
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        [titleLabel, detailLabel, sizeLabel, closeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview($0)
        }

        let padding: CGFloat = 16
        /// 顶部 60 是 cover 头部的遮挡区，内容从这里往下排
        let top: CGFloat = 76
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: top),
            titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: padding),
            titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -padding),

            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            detailLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: padding),
            detailLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -padding),

            sizeLabel.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 10),
            sizeLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: padding),
            sizeLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -padding),

            closeButton.topAnchor.constraint(equalTo: sizeLabel.bottomAnchor, constant: 12),
            closeButton.leftAnchor.constraint(equalTo: leftAnchor, constant: padding),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func updateSizeLabel(size: CGSize, container: CGSize) {
        sizeLabel.text = "内容区：\(Int(size.width)) x \(Int(size.height))\n容器：\(Int(container.width)) x \(Int(container.height))"
    }

    @objc private func close() {
        self.animationDismiss()
    }

    // MARK: ScreenPopupDelegate

    func screenPopupDidChange(_ change: ScreenPopupLayoutChange) {
        self.updateSizeLabel(size: change.frame.size, container: change.containerSize)
    }

    func screenPopupDidShow() {
        self.updateSizeLabel(size: frame.size, container: CGSize(width: kScreen.width, height: kScreen.height))
    }
}



