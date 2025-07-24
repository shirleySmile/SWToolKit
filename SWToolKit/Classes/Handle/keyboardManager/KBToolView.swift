//
//  KBToolView.swift
//  SWToolKit
//
//  Created by shirley on 2022/5/21.
//

import Foundation
import UIKit




class KBToolView: UIView {
    
    private lazy var currentBundle:Bundle? = {
        guard let path = Bundle(for: KBToolView.self).resourceURL ?? Bundle.main.resourceURL else { return nil }
        return Bundle.init(url: path)
    }()
    
    /// 下一个按钮
    public var nextBtnEnable:Bool = true {
        didSet{
            let imageStr = nextBtnEnable ? "arrow_black_down.png" : "arrow_gray_down.png"
            let img = UIImage(named: imageStr, in: currentBundle, compatibleWith: nil)
            nextImage.image = img
            nextBtn.isUserInteractionEnabled = nextBtnEnable
        }
    }
    /// 上一个按钮
    public var lastBtnEnable:Bool = true {
        didSet{
            let imageStr = lastBtnEnable ? "arrow_black_up.png" : "arrow_gray_up.png"
            let img = UIImage(named: imageStr, in: currentBundle, compatibleWith: nil)
            lastImage.image = img
            lastBtn.isUserInteractionEnabled = lastBtnEnable
        }
    }
    
    var doneBtn:UIButton!
    ///上一个
    var lastBtn:UIButton!
    ///下一个
    var nextBtn:UIButton!
    ///上一个图片
    var lastImage:UIImageView!
    ///下一个图片
    var nextImage:UIImageView!
    ///响应的view
    var becomeView:UIView?
    
    ///监听键盘的view上的subview
    var inputViews:[UIView]? {
        willSet{
            let next = ((newValue?.count ?? 0 ) > 1 ? true : false)
            lastBtn.isHidden = !next
            nextBtn.isHidden = !next
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func createUI(){
        
        self.backgroundColor = .white
        doneBtn = UIButton.init(frame: .zero)
        doneBtn.setTitle("Done", for: .normal)
        doneBtn.titleLabel?.font = .MSystemFont(13)
        doneBtn.setTitleColor(.black, for: .normal)
        self.addSubview(doneBtn)
        
        lastBtn = UIButton.init(frame: .zero)
        self.addSubview(lastBtn)
        lastImage = UIImageView.init(frame: .zero)
        lastImage.contentMode = .scaleAspectFit
        lastBtn.addTarget(self, action: #selector(lastBtnClick(btn:)), for: .touchUpInside)
        lastBtn.addSubview(lastImage)
        
        nextBtn = UIButton.init(frame: .zero)
        self.addSubview(nextBtn)
        nextImage = UIImageView.init(frame: .zero)
        nextImage.contentMode = .scaleAspectFit
        nextBtn.addTarget(self, action: #selector(nextBtnClick(btn:)), for: .touchUpInside)
        nextBtn.addSubview(nextImage)
        
        doneBtn.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.right.equalTo(self).inset(10)
        }
        
        lastBtn.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 40, height: 40))
            make.left.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
        }
        
        nextBtn.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 40, height: 40))
            make.left.equalTo(lastBtn.snp.right).inset(-10)
            make.centerY.equalToSuperview()
        }
        
        lastImage.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(15)
        }
        
        nextImage.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(15)
        }
        
        self.shadow(color: .lightGray.withAlphaComponent(0.5), opacity: 0.5, radius: 3, rectEdge: [.top], width: 1)
        
    }

    
    @objc func nextBtnClick(btn:UIButton) {
        otherTextInputHandle(last: false)
    }
    
    @objc func lastBtnClick(btn:UIButton) {
        otherTextInputHandle(last: true)
    }
    
    /// 处理其他的inputview
    /// - Parameter last: 是否为上一个
    private func otherTextInputHandle(last:Bool) {
        
        guard let subVs = inputViews else{
            return
        }
        
        for i in 0..<subVs.count {
            let curSubV = subVs[i]
            if last { ///上一个
                if curSubV.isFirstResponder && i > 0{
                    let lastV = subVs[i-1]
                    lastV.becomeFirstResponder()
                    handleCurrentInputV(currInputView: lastV, index: i-1)
                    break
                }
//                else{
//                    curSubV.resignFirstResponder()
//                }
            }else{  ///下一个
                if curSubV.isFirstResponder && i < subVs.count-1{
                    let nextV = subVs[i+1]
                    nextV.becomeFirstResponder()
                    handleCurrentInputV(currInputView: nextV, index: i+1)
                    break
                }
//                else{
//                    curSubV.resignFirstResponder()
//                }
            }
        }
    }
    
    ///处理当前becomeview 是否可以点上一个或下一个
    private func handleCurrentInputV(currInputView:UIView, index:Int){
        becomeView = currInputView
        guard let count = inputViews?.count else {
            return
        }
        if index == 0 {
            lastBtnEnable = false
            nextBtnEnable = true
        }else if index == count - 1 {
            lastBtnEnable = true
            nextBtnEnable = false
        }else{
            lastBtnEnable = true
            nextBtnEnable = true
        }
    }
    
    ///获取监听者
    func changeBecome(){
        guard let subVs = inputViews else{
            return
        }
        for i in 0..<subVs.count {
            let curSubV = subVs[i]
            if curSubV.isFirstResponder {
                handleCurrentInputV(currInputView: curSubV, index: i)
                curSubV.becomeFirstResponder()
                return
            }
        }
    }
    
    ///删除监听者
    func loseResign(){
        becomeView = nil
    }
    
    
}
