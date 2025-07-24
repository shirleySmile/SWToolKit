//
//  CNaviController.swift
//  SWToolKit
//
//  Created by shirley on 2022/4/14.
//

import Foundation
import UIKit

public class CNaviController: UINavigationController{
    
    public override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        viewController.hidesBottomBarWhenPushed = ((viewControllers.count == 0) ? false : true)
        super.pushViewController(viewController, animated: animated)
    }
        
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.interactivePop(open: true)
    }
    
    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        self.navigationBar.isHidden = true
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle:nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var childForStatusBarStyle: UIViewController?{
        return self.topViewController
    }
    
     
    ///禁止暗黑模式
    public override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    
}
