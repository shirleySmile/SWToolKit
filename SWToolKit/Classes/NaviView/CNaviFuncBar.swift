//
//  CNaviFuncBar.swift
//  SWToolKit
//
//  Created by shirley on 2023/6/16.
//

import UIKit


//MARK: 功能view
public class CNaviFuncBar: UIView{
    
    var _defaultBackImg:UIImage?
    var backBlock:(()->Void)?
    
    ///是否隐藏返回按钮 （外部不要直接设置）
    var isHiddenBackBtn:Bool = true{
        didSet{
            if isHiddenBackBtn == false {
                reloadLeftItems()
            }
        }
    }
    
    func dealloc(){
        self.backBlock = nil
        self.leftArr?.removeAll()
        self.rightArr?.removeAll()
        self.customTitleView?.removeFromSuperview()
        self.customTitleView = nil
        self.removeAllSubviews()
    }
    
    func initShowView(){
        reloadTitleInfo()
        reloadLeftItems()
        reloadRightItem()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    ///默认文字
    var titleStr:String?{
        didSet{
            if let titleStr = titleStr {
                attrTitleStr = NSAttributedString.init(string: titleStr, attributes: [.foregroundColor:titleColor])
            }
        }
    }
    var titleColor:UIColor = CNaviBar.barInfo.titleColor {
        didSet{
            if let titleStr = titleStr {
                attrTitleStr = NSAttributedString.init(string: titleStr, attributes: [.foregroundColor:titleColor])
            }
        }
    }
    
    ///或者默认文字
    var attrTitleStr:NSAttributedString?{
        didSet{
            reloadTitleInfo()
        }
    }
    
    ///用户自定义的标题
    var customTitleView:CNaviCustomTitleView?{
        didSet{
            reloadTitleInfo()
        }
    }
    
    ///标题
    var navTitleView:CNaviTitleView?{
        didSet{
            reloadTitleView(navTitleView)
        }
    }
    ///左侧按钮  有左侧按钮就不显示返回按钮
    var leftArr:[CNaviItemView]?{
        didSet{
            reloadLeftItems()
        }
    }
    ///右侧按钮
    var rightArr:[CNaviItemView]?{
        didSet{
            reloadRightItem()
        }
    }  
    ///返回按钮
    var backBtn:CNaviItemView?{
        didSet{
            reloadLeftItems()
        }
    }
    
    /// 刷新左侧的按钮
    private func reloadLeftItems() {
        ///显示左侧
        removeItemView(position: .left)
        if leftArr?.count ?? 0 > 0 {
            reloadLeftViewShow(list:leftArr!)
        }else{
            if !isHiddenBackBtn{
                if backBtn == nil {
                    backBtn = baseBackBtn()
                }
                reloadLeftViewShow(list: [backBtn!])
            }
        }
    }
    
    ///刷新右侧的按钮
    private func reloadRightItem() {
        removeItemView(position: .right)
        reloadRightViewShow(list: rightArr)
    }
    
    ///刷新标题内容的按钮
    private func reloadTitleInfo() {
        ///显示标题
        removeItemView(position: .center)
        if let customTitleV = customTitleView {
            navTitleView = customTitleV
        } else if attrTitleStr != nil{
            let defaultTitleView = CNaviTitleView.init()
            defaultTitleView.titleL?.attributedText = attrTitleStr
            navTitleView = defaultTitleView
        }
    }

    
    ///基本返回按钮
    fileprivate func baseBackBtn() -> CNaviItemView {
        let itemV = _defaultBackImg != nil ? CNaviItemView.navBackView(_defaultBackImg) : CNaviItemView.navBackView(CNaviBar.barInfo.backImage)
        itemV.addTarget(self, action: #selector(backBtnClick), for: .touchUpInside)
        return itemV
    }
    
    @objc fileprivate func backBtnClick(){
        print("===========hint CNaviBarView backBtnClick")
        self.backBlock?()
    }
    
    private lazy var backImg = UIImage(named: "")
}



extension CNaviFuncBar {
    
    ///显示标题view
    private func reloadTitleView(_ titleV:CNavItemBaseView?){
        if let titleV = titleV {
            titleV.navPosition = .center
            self.addSubview(titleV)
            titleV.snp.remakeConstraints { make in
                make.center.equalTo(self)
                if let cTitleV = titleV as? CNaviCustomTitleView, !cTitleV.isAutoSize, cTitleV.width > 0, cTitleV.height > 0 {
                    make.width.equalTo(cTitleV.width)
                    make.height.equalTo(cTitleV.height)
                }else{
                    make.width.lessThanOrEqualTo(kScreen.width - 100)
                    make.width.greaterThanOrEqualTo(1)
                }
            }
        }
    }
    
    ///刷新左边按钮
    private func reloadLeftViewShow(list:[CNaviItemView]?) {
        if let leftList = list {
            var leftV:UIView = self
                leftList.forEach { item in
                item.navPosition = .left
                self.addSubview(item)
                item.snp.remakeConstraints { make in
                    make.centerY.equalTo(self)
                    if item.frame.size.width > 0 || item.frame.size.height > 0 {
                        make.size.equalTo(item.frame.size)
                    }
                    if leftV == self {
                        if item == leftList.first && item != backBtn {
                            make.left.equalTo(leftV).inset(15)
                        }else{
                            make.left.equalTo(leftV).inset(15)
                        }
                    }else{
                        make.left.equalTo(leftV.snp.right).inset(-10)
                    }
                }
                leftV = item
            }
        }
    }
    
    ///刷新右边按钮
    private func reloadRightViewShow(list:[CNaviItemView]?) {
        if let rightList = list {
            var rightV:UIView = self
            rightList.forEach { item in
                item.navPosition = .right
                self.addSubview(item)
                item.snp.remakeConstraints { make in
                    make.centerY.equalTo(self)
                    if item.frame.size.width > 0 || item.frame.size.height > 0 {
                        make.size.equalTo(item.frame.size)
                    }
                    if rightV == self {
                        make.right.equalTo(rightV).inset(15)
                    }else{
                        make.right.equalTo(rightV.snp.left).inset(-10)
                    }
                    
                }
                rightV = item
            }
        }
    }
    
    ///删除功能view上的子试图
    private func removeItemView(position:CNaviItemView.ViewPosition) {
        subviews.forEach { view in
            if let subV = view as? CNavItemBaseView{
                if subV.navPosition == position {
                    subV.removeFromSuperview()
                }
            }
        }
    }
}




//MARK: 默认titleView
class CNaviTitleView: CNavItemBaseView{
    
    var titleL:UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.navPosition = .center

        titleL = UILabel.init(frame: .zero)
        self.addSubview(titleL!)
        titleL?.font = UIFont.MSystemFont(17, .medium)
        titleL?.textColor = CNaviBar.barInfo.titleColor
        titleL?.textAlignment = .center
        titleL?.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleL?.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleL?.snp.makeConstraints({ make in
            make.edges.equalTo(self)
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


//MARK: 封装自定义的titleview
class CNaviCustomTitleView:CNaviTitleView{
    var viewW:CGFloat = 0
    var viewH:CGFloat = 0
    var isAutoSize:Bool = false
    var titleV:UIView?
    init(view:UIView?) {
        super.init(frame: view?.bounds ?? .zero)
        
        self.navPosition = .center
        
        titleL?.removeFromSuperview()
        titleL = nil
        
        viewW = view?.width ?? 0
        viewH = view?.height ?? 0
        titleV = view

        if let v = view {
            if viewW > 0 && viewH > 0 {
                view?.origin = .zero
                addSubview(v)
            }else{
                isAutoSize = true
                addSubview(v)
                v.snp.makeConstraints { make in
                    make.top.left.right.bottom.equalToSuperview()
                }
            }
        }
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitV = super.hitTest(point, with: event)
        print("hint CNaviCustomTitleView") 
        return hitV
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
