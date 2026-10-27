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
        btn3.frame = .init(x: 280, y: 500, width: 100, height: 20)
        btn3.setTitle("显示弹窗3", for: .normal)
        btn3.setTitleColor(.red, for: .normal)
        self.view.addSubview(btn3)
        btn3.addTarget(self, action: #selector(click3), for: .touchUpInside)
        
        let btn4 = UIButton(type: .custom)
        btn4.frame = .init(x: 20, y: 560, width: 100, height: 20)
        btn4.setTitle("内购测试", for: .normal)
        btn4.setTitleColor(.blue, for: .normal)
        self.view.addSubview(btn4)
        btn4.addTarget(self, action: #selector(clickIAPDemo), for: .touchUpInside)
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
    }
    
    
    @objc func click1(){
        AlertView.show()
    }

    
    @objc func click2(){
        let view:UIView = .init(frame: .init(x: 0, y: 0, width: kScreen.width, height: 200))
        view.backgroundColor = .red.withAlphaComponent(0.7)
        view.screenPopupShow(animation: .enterFromTop())
    }
    
    @objc func click3() {
        let vc = ScreenViewController()
        self.present(vc, animated: true)
    }
    
    @objc func clickIAPDemo() {
        let vc = IAPDemoViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

class AlertView:UIView {
    
    static func show() {
        
        let view = AlertView(frame: .init(origin: .zero, size: .init(width: kScreen.width, height: 300)))
        view.animationShow(header: .init(view: SheetBorderSliderHeader.init(viewHeight: 60), type: .cover))
    }
    
    
    
}



