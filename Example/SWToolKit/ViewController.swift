//
//  ViewController.swift
//  SWToolKit
//
//  Created by shirley on 07/24/2025.
//

import UIKit
import SWToolKit


class ViewController: UIViewController {

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
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

