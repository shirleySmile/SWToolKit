//
//  NaviController.swift
//  SWToolKit_Example
//
//  Created by muwa on 2026/11/2.
//  Copyright © 2026 CocoaPods. All rights reserved.
//


import UIKit


class NaviController:UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showNaviView()
        
        
        let btn4 = UIButton(type: .custom)
        btn4.frame = .init(x: 20, y: 560, width: 100, height: 20)
        btn4.setTitle("no message", for: .normal)
        btn4.setTitleColor(.blue, for: .normal)
        self.view.addSubview(btn4)
    }
    
}
