//
//  ViewPop.swift
//  SWToolKit_Example
//
//  Created by muwa on 2025/12/1.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import SwiftUI
import UIKit
import SWToolKit


class ScreenViewController: UIViewController {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let vc = UIHostingController(rootView: ScreenView()).view {
            vc.frame = self.view.bounds
            /// 跟随承载页尺寸变化（旋转 / iPad 分屏）
            vc.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(vc)
        }

        let backBtn = UIButton(type: .custom)
        backBtn.setTitle("返回", for: .normal)
        backBtn.backgroundColor = .red.withAlphaComponent(0.5)
        self.view.addSubview(backBtn)
        backBtn.frame = .init(x: 20, y: 60, width: 100, height: 30)
        backBtn.addTarget(self, action: #selector(backBtnClick), for: .touchUpInside)
    }
    
    @objc func backBtnClick() {
        self.dismiss(animated: true)
    }
    
}



struct ScreenView: View {
    
    var body: some View {
        GeometryReader { gr in
            ZStack {
                Button("显示弹窗") {
                    
                    ViewPopView.show()
                    
                }.background(Color.blue.opacity(0.4))
            }.frame(width: gr.size.width, height: gr.size.height)
        }
    }
}



struct ViewPopView: View {
    
    static func show() {
        let view = ViewPopView()
        view.animationShow(key: "ViewPopView", viewFrame: .init(x: 0, y: 0, width: kScreen.width, height: 500), cornerSize: .init(width: 20, height: 20))
    }
    

    var body: some View {
        GeometryReader { gr in
            ZStack {
                Button("关闭弹窗") {
                    
                    self.animationDismiss(key: "ViewPopView")
                    
                }.background(Color.blue.opacity(0.4))
                
            }.frame(width: gr.size.width, height: gr.size.height)
                .background(Color.red.opacity(0.1))
        }
        
        
    }
    
    
}


// MARK: - 屏幕旋转 / 尺寸变化测试

/// sheet 内容：旋转或 iPad 分屏后，展示内容区新尺寸，并验证内部 Auto Layout 重排
final class RotationTestView: UIView, ScreenPopupDelegate {

    private let containerLabel = UILabel()
    private let sizeLabel = UILabel()
    private let noteLabel = UILabel()
    private let textField = UITextField()
    private let noneButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupUI()
        updateLabels(container: CGSize(width: kScreen.width, height: kScreen.height), frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        [containerLabel, sizeLabel, noteLabel, textField, noneButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        containerLabel.font = .boldSystemFont(ofSize: 15)
        containerLabel.numberOfLines = 0

        sizeLabel.font = .systemFont(ofSize: 14)
        sizeLabel.textColor = .darkGray
        sizeLabel.numberOfLines = 0

        noteLabel.font = .systemFont(ofSize: 13)
        noteLabel.textColor = .gray
        noteLabel.numberOfLines = 0
        noteLabel.text = "旋转设备 / 拖动 iPad 分屏，观察上面的尺寸和下面的输入框是否跟随新宽度重排。"

        textField.borderStyle = .roundedRect
        textField.placeholder = "输入框会保持左右贴边"

        noneButton.setTitle("再弹一个 .none 弹窗", for: .normal)
        noneButton.addTarget(self, action: #selector(showNonePopup), for: .touchUpInside)

        let padding: CGFloat = 16
        NSLayoutConstraint.activate([
            containerLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            containerLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: padding),
            containerLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -padding),

            sizeLabel.topAnchor.constraint(equalTo: containerLabel.bottomAnchor, constant: 8),
            sizeLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: padding),
            sizeLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -padding),

            noteLabel.topAnchor.constraint(equalTo: sizeLabel.bottomAnchor, constant: 12),
            noteLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: padding),
            noteLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -padding),

            textField.topAnchor.constraint(equalTo: noteLabel.bottomAnchor, constant: 16),
            textField.leftAnchor.constraint(equalTo: leftAnchor, constant: padding),
            textField.rightAnchor.constraint(equalTo: rightAnchor, constant: -padding),
            textField.heightAnchor.constraint(equalToConstant: 44),

            noneButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 16),
            noneButton.leftAnchor.constraint(equalTo: leftAnchor, constant: padding),
            noneButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func updateLabels(container: CGSize, frame: CGRect) {
        containerLabel.text = "容器可用区域：\(Int(container.width)) x \(Int(container.height))"
        sizeLabel.text = "内容区：\(Int(frame.width)) x \(Int(frame.height))\n当前屏幕：\(Int(kScreen.width)) x \(Int(kScreen.height))"
    }

    // MARK: ScreenPopupDelegate

    func screenPopupDidChange(_ change: ScreenPopupLayoutChange) {
        updateLabels(container: change.containerSize, frame: change.frame)
    }

    func screenPopupDidShow() {
        updateLabels(container: CGSize(width: kScreen.width, height: kScreen.height), frame: frame)
    }

    @objc private func showNonePopup() {
        let width = min(320, kScreen.width - 32)
        let card = RotationTestCardView(frame: CGRect(x: kScreen.width - width - 16, y: 80, width: width, height: 200))
        var options = ScreenPopupOptions()
        options.animation = .none
        options.cover = .black.withAlphaComponent(0.25)
        /// 未显式传 delegate 时，内容 view 自己实现协议就会作为 delegate
        card.screenPopupShow(options: options)
    }
}


/// .none 弹窗：验证“归一化中心 + 全宽跟随 / 非全宽夹取”
final class RotationTestCardView: UIView, ScreenPopupDelegate {

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBlue.withAlphaComponent(0.9)
        layer.cornerRadius = 12
        clipsToBounds = true

        label.numberOfLines = 0
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        label.frame = bounds.insetBy(dx: 16, dy: 16)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(label)
        updateLabel(frame: frame, container: CGSize(width: kScreen.width, height: kScreen.height))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateLabel(frame: CGRect, container: CGSize) {
        label.text = ".none 弹窗\n自身：\(Int(frame.width)) x \(Int(frame.height))\n中心：\(Int(frame.midX)), \(Int(frame.midY))\n容器：\(Int(container.width)) x \(Int(container.height))\n\n点外部关闭"
    }

    // MARK: ScreenPopupDelegate

    func screenPopupDidChange(_ change: ScreenPopupLayoutChange) {
        updateLabel(frame: change.frame, container: change.containerSize)
    }

    func screenPopupDidShow() {
        updateLabel(frame: frame, container: CGSize(width: kScreen.width, height: kScreen.height))
    }
}
