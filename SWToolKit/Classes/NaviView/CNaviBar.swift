//
//  CNaviBar.swift
//  SWToolKit
//
//  Created by shirley on 2022/4/14.
//

import Foundation
import UIKit
import SnapKit

public struct CNaviBarBaseInfo {
    var textColor:UIColor
    var tintColor:UIColor
    var tapShark:Bool
    
    public init(textColor: UIColor, tintColor: UIColor, tapShark: Bool) {
        self.textColor = textColor
        self.tintColor = tintColor
        self.tapShark = tapShark
    }
}



//MARK: 导航栏底图
class CNaviBgView: UIView {
    ///磨砂透明
    private weak var blurView: UIVisualEffectView?
    
    private var bgA:CGFloat = 1.0
    ///背景图片
    private lazy var navBgImgV: UIImageView = {
        let imgV = UIImageView.init(frame: self.bounds)
        self.addSubview(imgV)
        self.sendSubviewToBack(imgV)
        return imgV
    }()

    override init(frame: CGRect) {
        super.init(frame:frame)
        backgroundColor = .clear
        alpha = bgA
        clipsToBounds = true
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate var bgImage:UIImage?{
        didSet{
            if let img = bgImage {
                navBgImgV.image = img
            }else{
                navBgImgV.image = nil
            }
        }
    }
    
    func bgAlpha(a:CGFloat){
        bgA = a
        navBgImgV.alpha = a
        blurView?.alpha = a
    }
    
    func addBlurView(_ blur:UIVisualEffect?) {
        blurView?.removeFromSuperview()
        if let blur {
            let visualView = UIVisualEffectView.init(effect: blur)
            visualView.isUserInteractionEnabled = false
            visualView.frame = self.bounds
            self.addSubview(visualView)
            self.sendSubviewToBack(visualView)
            self.blurView = visualView
            visualView.alpha = bgA
        }
    }
    
    func bgColor(color:UIColor?) {
        navBgImgV.backgroundColor = color
    }
    
}



public class CNaviBarView: UIControl {
    
    ///底层
    fileprivate weak var navBarBgView:CNaviBgView?
    ///功能底层
    public private(set) var funcBar = CNaviFuncBar()
    ///底部分割线
    fileprivate var navBtmLineV: UIView = {
        let v = UIView()
//        v.isHidden = true
        return v
    }()

    fileprivate var isRegKVO:Bool = false
    ///当前controller返回
    fileprivate weak var currentVC:UIViewController?{
        willSet{
            if let oldVC = currentVC, isRegKVO {
                oldVC.removeObserver(self, forKeyPath: "frame")
            }
            if let currVC = newValue {
                isRegKVO = true
                currVC.view.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
            }
        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let view = object as? UIView, currentVC?.view == view, let bgView = navBarBgView {
//            self.superview?.bringSubviewToFront(self)
            view.bringSubviewToFront(bgView)
        }
    }
    
    ///初始化
    init(bgView:CNaviBgView) {
        super.init(frame:bgView.bounds)
        
        navBarBgView = bgView
        
        bgView.addSubview(self)
        
        self.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action:nil))
        
        funcBar = CNaviFuncBar(frame: .init(x: 0, y: kStatusBarH, width: bgView.width, height: bgView.height-kStatusBarH))
        funcBar.initShowView()
        funcBar.backBlock = {[weak self] in
            if let navc = self?.currentVC?.navigationController {
                navc.popViewController(animated: true)
            }else{
                self?.currentVC?.dismiss(animated: true)
            }
        }

        navBtmLineV.frame = CGRect(x: 0, y: self.frame.height-0.6, width: self.frame.width, height: 0.1)
        ///添加view
        bgView.addSubview(funcBar)
        self.addSubview(navBtmLineV)
        self.backgroundColor = .clear
        
        navBarBgView?.bgColor(color: CNaviBar.barInfo.tintColor)
        
        navBtmLineV.shadow(color: .black, opacity: 0.3, radius: 1, rectEdge: .bottom, width: 0.5)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var alpha: CGFloat {
        didSet{
            navBarBgView?.alpha = alpha
        }
    }
    
}



///本扩展类的内容为使用方式 ----  不要直接使用
let cNaviBarTag = 999999999
extension CNaviBar {
    
    ///显示导航栏    ---     不掉用不显示
    func showNaviView(show showBackBtn:Bool) {
        funcBar.isHiddenBackBtn = !showBackBtn
        navBarBgView?.superview?.bringSubviewToFront(navBarBgView!)
        navBarBgView?.frame.size = CGSize(width: kScreen.width, height: kNaviH)
        navBarBgView?.isHidden = false
    }
    
    
    ///隐藏导航栏
    func hiddenNaviView() {
        navBarBgView?.isHidden = true
        navBarBgView?.contentMode = .scaleToFill
        navBarBgView?.frame.size = CGSize(width: kScreen.width, height: 0);
    }
    
    
    ///获取当前UI
    static func getNaviView(currVC:UIViewController) -> CNaviBar{
        var navBar:CNaviBar? = currVC.view.viewWithTag(cNaviBarTag) as? CNaviBar
        if navBar == nil {
            let bgView = CNaviBgView.init(frame: .init(x: 0, y: 0, width: kScreen.width, height: kNaviH))
            navBar = CNaviBar.init(bgView: bgView)
            navBar!.tag = cNaviBarTag
            currVC.view.addSubview(bgView)
            navBar?.currentVC = currVC
            navBar?.hiddenNaviView()
        }
        return navBar!
    }
    
}




//MARK: 自定义 CNaviBar   ---   可直接使用，此处为外部设置，不赋值会使用默认值
public class CNaviBar: CNaviBarView {
    
    public static var barInfo = CNaviBarBaseInfo.init(textColor: UIColor.black, tintColor: UIColor.white, tapShark: false)


    deinit {
        rightItemArr?.removeAll()
        leftItemArr?.removeAll()
        self.funcBar.dealloc()
        self.funcBar.removeFromSuperview()
        self.removeAllSubviews()
        self.removeFromSuperview()
    }

    /// 左侧按钮  ---  有左侧按钮就不显示返回按钮， 第一个按钮默认距左15pt ， 第二个按钮距离第一个按钮3pt
    public var leftItemArr:[CNaviItemView]?{
        willSet{
            funcBar.leftArr = newValue
        }
    }
    
    /// 右侧按钮 第一个按钮默认距右15pt ， 第二个按钮距离第一个按钮3pt
    public var rightItemArr:[CNaviItemView]?{
        willSet{
            funcBar.rightArr = newValue
        }
    }
    
    /// 标题位置的View，居中显示
    public var titleView:UIView?{
        willSet {
            if let titleV = newValue {
                funcBar.customTitleView = CNaviCustomTitleView(view: titleV)
            }else{
                funcBar.customTitleView = nil
            }
        }
    }
    
    /// 导航栏标题文字
    public var title:String?{
        willSet{
            funcBar.titleStr = newValue
            if let titleV = funcBar.navTitleView as? CNaviTitleView {
                titleV.titleL?.text = newValue
            }
        }
    }
    
    /// 导航栏标题文字
    public var attrTitle:NSAttributedString?{
        willSet{
            funcBar.attrTitleStr = newValue
            if let titleV = funcBar.navTitleView as? CNaviTitleView {
                titleV.titleL?.attributedText = newValue
            }
        }
    }
    
    /// 设置标题文字颜色
    public var titleColor:UIColor?{
        willSet{
            if let value = newValue {
                funcBar.titleColor = value
                if let titleV = funcBar.navTitleView as? CNaviTitleView {
                    titleV.titleL?.textColor = newValue
                }
            }
        }
    }
    
    /// 设置背景色
    public override var backgroundColor: UIColor? {
        didSet {
            navBarBgView?.bgColor(color: backgroundColor)
            super.backgroundColor = .clear
        }
    }
    
    /// 是否显示磨砂层
    public var blurEffect:UIVisualEffect? {
        willSet{
            navBarBgView?.addBlurView(newValue)
        }
    }

    /// 设置背景透明度, 导航栏的按钮没有透明度
    public var bgAlpha:CGFloat = 1.0{
        willSet{
            navBarBgView?.bgAlpha(a: newValue)
        }
    }
    
    /// 导航栏背景图片
    public var navBgImage:UIImage?{
        willSet{
            navBarBgView?.bgImage = newValue
        }
    }
    
    /// 是否显示导航栏底部线
    public var showBottomLine:Bool?{
        willSet{
            if let value = newValue {
                navBtmLineV.isHidden = !value
            }
        }
    }

    /// 只修改返回按钮的图片 不赋值默认是黑色的返回按钮
    public var navBackImage:UIImage?{
        willSet{
            if let value = newValue {
                funcBar._defaultBackImg = value
                if let item:CNaviItemView = funcBar.backBtn, let imageV:UIImageView = item.viewWithTag(9999) as? UIImageView {
                    imageV.image = value
                }
            }
        }
    }
    
    /// 设置返回按钮, 点击事件也自己写
    public var resetBackBtn:CNaviItemView?{
        willSet{
            if let value = newValue {
                funcBar.backBtn = value
            }
        }
    }
    
    /// 是否隐藏返回按钮
    public var isHiddenBackBtn:Bool = false{
        willSet{
            funcBar.isHiddenBackBtn = isHiddenBackBtn
            funcBar.backBtn?.isHidden = newValue
        }
    }

    
}













