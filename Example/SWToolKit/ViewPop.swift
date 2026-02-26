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
