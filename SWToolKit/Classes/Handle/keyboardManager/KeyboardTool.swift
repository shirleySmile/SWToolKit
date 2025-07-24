//
//  KeyboardTool.swift
//  SWToolKit
//
//  Created by shirley on 2022/5/21.
//

import Foundation
import UIKit


fileprivate class KBSubInputViews:NSObject{
    
    struct BecommongView {
        var bView:UIView
        var kbType:UIKeyboardType
    }
    
    fileprivate var oldBecomingView:BecommongView?
    fileprivate var currentKBHeight:CGFloat = 0
    fileprivate var inputViews:[BecommongView]?
    
    private weak var obserView:UIView?
    ///inputview的管理工具
    private(set) var toolView:KBToolView?
    
    
    private(set) var isShow:Bool = false
    
    deinit {
        toolView?.inputViews?.removeAll()
        toolView = nil
        oldBecomingView = nil
        inputViews?.removeAll()
        currentKBHeight = 0
    }
    
    init(observerView :UIView?, hasToolView:Bool) {
        super.init()
        self.obserView = observerView
        if hasToolView {
            self.toolView = KBToolView.init(frame: CGRect(x: 0, y: 0, width: kScreen.width, height: 40))
            self.toolView?.doneBtn.tapView {[weak self] in
                self?.obserView?.endEditing(true)
            }
        }
    }
    
    /// 修改监听的view
    func keyBoardWillChange(will show:Bool){
        if isShow == show {
            return
        }
        isShow = show
        if show {
            self.addObserView()
        }else{
            self.oldBecomingView = nil
        }
    }
    
    
    fileprivate func addObserView(){
        if let obView = self.obserView {
            self.inputViews?.removeAll()
            var inputs:[UIView] = Array()
            var subViews = [BecommongView]()
            self.getSubInputViews(baseView: obView) { subV, type in
                subViews.append(BecommongView.init(bView: subV, kbType: type))
                inputs.append(subV)
            }
            if subViews.count > 0 {
                self.inputViews = subViews
            }
            toolView?.inputViews = inputs
        }
    }

    fileprivate var firstResponderView:BecommongView?{
        get{
            if let inputViews = inputViews {
                for subV in inputViews {
                    if subV.bView.isFirstResponder {
                        return subV
                    }
                }
            }
            return nil
        }
    }

    ///获取子视图为输入View
    private func getSubInputViews(baseView:UIView, subInputVs:(UIView, UIKeyboardType)->Void){
        if let ttv = baseView as? UITextView, ttv.isUserInteractionEnabled && ttv.isEditable{
            ttv.inputAccessoryView = toolView
            subInputVs(baseView, ttv.keyboardType)
        }else if let tfv = baseView as? UITextField, tfv.isUserInteractionEnabled{
            tfv.inputAccessoryView = toolView
            subInputVs(baseView, tfv.keyboardType)
        }else {
            baseView.subviews.forEach {[weak self] subV in
                self?.getSubInputViews(baseView: subV, subInputVs: subInputVs)
            }
        }
    }
    
}







public class KeyboardTool:NSObject{
    
    deinit {
        print(#file,"======单例文件异常销毁======")
    }
    
    private static let share = KeyboardTool()
    private var scrollStyle:AbserverMoveStyle = .none
    private var kbInputViews:KBSubInputViews?
    /// 原点
    private var originalFrame:CGRect = CGRect.zero
    /// 监听键盘的view
    private weak var observerView:UIView?
    
    private var viewOrInputDistance:CGFloat = 0

    fileprivate var startAnimation:((Bool, TimeInterval)->Void)?
    fileprivate var completeAnimation:((Bool)->Void)?
    
    
    private func tapEndViewEditing(){
        observerView?.tapView {[weak self] in
            self?.observerView?.endEditing(true)
        }
    }
    
    ///添加监听者管理
    private func addObserverManager(obj:AnyObject?, showToolV:Bool, distance:Float) {
        viewOrInputDistance = CGFloat(distance)
        observerView = getObserverView(obj: obj)
        kbInputViews = KBSubInputViews.init(observerView: observerView, hasToolView: showToolV)
        kbInputViews?.addObserView()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notify:)), name: UIWindow.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notify:)), name: UIWindow.keyboardWillHideNotification , object: nil)
        if #available(iOS 13, *) {  }else{
            NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidBeginEditing(notify:)), name: UITextField.textDidBeginEditingNotification , object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(textViewDidBeginEditing(notify:)), name: UITextView.textDidBeginEditingNotification , object: nil)
        }
    }
    
    private func removeObserverManager(){
        guard let abView = observerView else { return }
        if kbInputViews?.oldBecomingView != nil{
            kbWillHide(abView: abView, time: 0.25)
        }
        viewOrInputDistance = CGFloat(0)
        observerView = nil
        kbInputViews?.inputViews?.removeAll()
        kbInputViews = nil
        NotificationCenter.default.removeObserver(self, name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIWindow.keyboardWillHideNotification, object: nil)
        if #available(iOS 13, *) {  }else{
            NotificationCenter.default.removeObserver(self, name: UITextField.textDidBeginEditingNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UITextView.textDidBeginEditingNotification, object: nil)
        }
    }
    

    @objc func textViewDidBeginEditing(notify:Notification){
        if #available(iOS 13, *) {
            print("ios 13及以上")
        }else{
            if kbInputViews?.oldBecomingView != nil {
                print("textViewDidBeginEditing\n" + String(describing: notify.object) + "\n" + String(describing: notify.userInfo))
                /// 先不处理，遇到再说
            }
        }
    }
    
    @objc func textFieldDidBeginEditing(notify:Notification){
        if #available(iOS 13, *) {
            print("ios 13及以上")
        }else{
            guard let abView = observerView else{
                return
            }
            if let kbHeight = kbInputViews?.currentKBHeight, kbHeight > 0{
                print("textFieldDidBeginEditing\n" + String(describing: notify.object) + "\n" + String(describing: notify.userInfo))
                kbWillShow(abView: abView, kbRect: .init(x: 0, y: kScreen.height-kbHeight, width: kScreen.width, height: kbHeight), time: 0.02)
            }
        }
    }
    
    ///显示
    @objc func keyboardWillShow(notify:Notification) {
        guard let abView = observerView else{
            return
        }
        guard let localAppKB = notify.userInfo?[UIWindow.keyboardIsLocalUserInfoKey], localAppKB as! Int == 1 else {
            return
        }
        abView.layer.removeAllAnimations()
        abView.layoutIfNeeded()
        
//        kbInputViews?.keyBoardWillChange(will: true)
        kbInputViews?.toolView?.changeBecome()
        
        let time = notify.userInfo?[UIWindow.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        let kbRect = (notify.userInfo?[UIWindow.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        kbWillShow(abView: abView, kbRect: kbRect, time: time)
    }
    
    
    ///隐藏
    @objc func keyboardWillHide(notify:Notification) {
        guard let abView = observerView else{
            return
        }
//        kbInputViews?.keyBoardWillChange(will: false)
        self.kbInputViews?.oldBecomingView = nil
        let time = notify.userInfo?[UIWindow.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        kbWillHide(abView: abView, time: time)
    }
    
    /// 通用 键盘显示
    private func kbWillShow(abView:UIView, kbRect:CGRect, time:TimeInterval){
        let originalF = originalFrame
//        print("【键盘】keyboardWillShow originalFrame == \(originalFrame)")
        let defaultSpace = viewOrInputDistance
        if scrollStyle == .translation {
            self.startAnimation?(true, max(time, 0.02))
            UIView.animate(withDuration: max(time, 0.02)) {
                abView.y = kScreen.height - (kbRect.height + originalF.size.height) - defaultSpace
                abView.layoutIfNeeded()
            } completion: { finish in
                if finish {
                    self.completeAnimation?(true)
                }
            }
        }else if scrollStyle == .changeHeight {
            let windowFrame = abView.superview?.convert(abView.frame, to: kHighWindow)
            let spaceH = kbRect.origin.y - (windowFrame?.maxY ?? 0)
            self.startAnimation?(true, max(time, 0.02))
            UIView.animate(withDuration: max(time, 0.02)) {
                abView.height = abView.size.height + spaceH
                abView.layoutIfNeeded()
            } completion: { finish in
                if finish {
                    self.completeAnimation?(true)
                }
            }
            if let kbInputViews = kbInputViews,let becomingView = kbInputViews.firstResponderView, abView.isKind(of: UIScrollView.self) {
                let abScrollView = abView as! UIScrollView
                let scrollVFrame = becomingView.bView.superview?.convert(becomingView.bView.frame, to: abScrollView)
                let y = max(0, (scrollVFrame?.maxY ?? 0) + defaultSpace - abScrollView.height)
                if abScrollView.contentOffset.y != y {
                    UIView.animate(withDuration: max(time, 0.02)) {
                        abScrollView.setContentOffset(.init(x: 0, y: y), animated: true)
                    }
                }
                kbInputViews.oldBecomingView = becomingView
                kbInputViews.currentKBHeight = kbRect.height
            }
        }else if scrollStyle == .follow {
            if let kbInputViews = kbInputViews,let becomingView = kbInputViews.firstResponderView{
                func animationView(){
                    let winFrame = becomingView.bView.superview?.convert(becomingView.bView.frame, to: kHighWindow)
                    let spaceH = kbRect.origin.y - ((winFrame?.maxY ?? 0) + defaultSpace)
                    let y = (spaceH <= 0 || spaceH >= defaultSpace-10) ? min((abView.y + spaceH - defaultSpace), originalF.origin.y) : originalF.origin.y
                    self.startAnimation?(true, max(time, 0.02))
                    UIView.animate(withDuration: max(time, 0.02)) {
                        abView.y = y
                        abView.layoutIfNeeded()
                    } completion: { finish in
                        if finish {
                            self.completeAnimation?(true)
                        }
                    }
                    kbInputViews.oldBecomingView = becomingView
                }
                animationView()
                kbInputViews.currentKBHeight = kbRect.height
            }
        }
    }
    
    
    
    /// 通用 键盘隐藏
    private func kbWillHide(abView:UIView, time:TimeInterval){
        abView.layer.removeAllAnimations()
        abView.layoutIfNeeded()
        kbInputViews?.toolView?.loseResign()
        let originalF = originalFrame
        if scrollStyle == .translation || scrollStyle == .follow {
            self.startAnimation?(false, time)
            UIView.animate(withDuration: time) {
                abView.y = originalF.origin.y
                abView.layoutIfNeeded()
            } completion: { finish in
                if finish {
                    self.completeAnimation?(false)
                }
            }
        }
        if scrollStyle == .changeHeight {
            self.startAnimation?(false, time)
            UIView.animate(withDuration: time) {
                abView.height = originalF.size.height
                abView.layoutIfNeeded()
            } completion: { finish in
                if finish {
                    self.completeAnimation?(false)
                }
            }
        }
    }
    
    
    private func getObserverView(obj:AnyObject?) -> UIView? {
        var observerView:UIView?
        if obj is UIViewController {
            let vc = obj as! UIViewController
            
            var hasInputView = false
            var otherView:UIView?
            for subView in vc.view.subviews {
                if subView.isMember(of: CNaviBgView.self) {
                    subView.superview?.bringSubviewToFront(subView)
                }
                if subView.width == kScreen.width && subView.height >= (kScreen.height-kNaviH-kTabBarH){
                    otherView = subView
                }
                if subView.isKind(of: UITextView.self) || subView.isKind(of: UITextField.self){
                    hasInputView = true
                }
            }
            if let otherView = otherView, !hasInputView{
                observerView = otherView
            }else{
                observerView = vc.view
            }
        } else if obj is UIView{
            observerView = obj as? UIView
            for subView in kCurrentVC?.view.subviews ?? [] {
                if subView.isMember(of: CNaviBgView.self) {
                    subView.superview?.bringSubviewToFront(subView)
                }
            }
        } else{
            observerView = nil
        }
        originalFrame = observerView?.frame ?? CGRect.zero
        return observerView
    }
    
}



extension KeyboardTool {
    
    
    public enum AbserverMoveStyle {
        /// 不做任何改变
        case none
        /// view整体向上平移在键盘之上
        case translation
        /// 改变view的尺寸, x坐标不变而高度改变，如果view是scrollView，当前相应输入框可以移动到键盘上面
        case changeHeight
        /// 跟随,  输入框在键盘上
        case follow
    }
    
    
    
    /// 添加键盘监听,只能监听一个animationObj文件，添加新的会将就的删除. 建议放在页面都设置完后再使用此方法（尤其是layout页面），要不找不到子视图中的inputview
    /// - Parameters:
    ///   - animationObj: 传入需要移动的UIView或者viewcontroller,
    ///     viewcontroller默认使用的是VC上的view，如果vc的view上有导航栏，会选择view尺寸比较大的一个
    ///   - style: 移动样式, 默认不移动
    ///   - showToolView: 是否显示工具栏
    ///   - distance: style为跟随或者改变view的尺寸时，animationObj上输入框距离底部的最小距离
    ///   - tapEndEditing: 点击监听的view后是否关闭键盘
    @discardableResult
    public static func addKBNotification(_ animationObj:AnyObject, style:AbserverMoveStyle = .none, showToolView:Bool = false, distance:Float = 0, tapEndEditing:Bool = true) -> KeyboardTool {
        removeKBNotification()
        KeyboardTool.share.scrollStyle = style
        KeyboardTool.share.addObserverManager(obj: animationObj, showToolV: showToolView, distance: distance)
        if tapEndEditing {
            KeyboardTool.share.tapEndViewEditing()
        }
        return KeyboardTool.share
    }
    
    /// 监听结束后调用次方法
    @discardableResult
    public static func removeKBNotification() {
        KeyboardTool.share.removeObserverManager()
    }
    
    
    /// 动画开始或者结束
    public func animationBlock(start:((_ isShow:Bool,_ time:TimeInterval)->Void)? = nil, complate:((_ isShow:Bool)->Void)? = nil){
        self.startAnimation = start
        self.completeAnimation = complate
    }
    
}


