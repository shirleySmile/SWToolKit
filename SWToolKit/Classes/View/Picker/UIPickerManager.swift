//
//  UIPickerManager.swift
//  SWToolKit
//
//  Created by shirley on 2022/5/26.
//

import Foundation
import UIKit
import SwiftUI

/// 选择的数据
public class PickerSelectInfo:NSObject {
    /// 第几个
    public var index:Int = 0
    /// 显示的内容
    public var show:String!
    /// 原始的内容
    public var original:String!
    
    public init(_ info:PickerShowInfo?, index selectIndex:Int) {
        if let info = info {
            index = selectIndex
            show = info.showStr
            original = info.originalStr
        }else{ /// -1代表没有数据
            index = -1
            show = ""
            original = ""
        }
    }
}


/// 设置显示的数据
public class PickerShowInfo: NSObject{
    /// 显示的内容
    public var showStr:String!
    /// 原始的内容
    public var originalStr:String!
    /// 下一级显示的内容 （多级联动的将下一级的放到这里）
    public var subList:[PickerShowInfo]?
    
    public init(show:String, original:String) {
        showStr = show
        originalStr = original
    }
}


public class UIPickerManager: UIView {
    
    public var pickerV:UIPickerView!
    ///是否联动
    public var linkage:Bool = false
    
    ///数组中有多个值时，默认不联动
    public var pickerShowInfoList:[Array<PickerShowInfo>]! = Array()
    
    /// 选择的行（最多三级）
    public var selectedRows:[Int] = [0,0,0]
    
    ///联动为几列 (限制最多三级)
    public var linkageNumber:UInt = 1
    
    
    ///没有设定选中某个值时，默认选中第几个
    public var defailtInitSelectNum:[UInt]?{
        didSet{
            print(defailtInitSelectNum ?? "");
            pickerV.layoutIfNeeded()
            if let defailtInitSelectNum = self.defailtInitSelectNum, defailtInitSelectNum.count > 0 {
                for i in 0..<defailtInitSelectNum.count {
                    if i < self.pickerV.numberOfComponents{
                        self.pickerV.reloadComponent(i)
                        let maxNum = self.pickerV.numberOfRows(inComponent: i)
                        let seletNum = defailtInitSelectNum[i]
                        self.pickerV.selectRow(min(((maxNum > 0) ? (maxNum - 1) : 0), Int(seletNum)), inComponent: i, animated: false)
                    }
                }
                self.currentSelect()
            }
            defailtInitSelectNum = nil
        }
    }
    
    ///回调
    private var selectClosure:(([PickerSelectInfo])->Void)?
    
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        pickerV = UIPickerView.init(frame: self.bounds)
        pickerV.delegate = self
        pickerV.dataSource = self
        self.addSubview(pickerV)
        pickerV.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    ///选择的数据
    public func selectValue(result:@escaping(([PickerSelectInfo])->Void)){
        selectClosure = result
    }
    
    public func reloadShow(){
        if pickerShowInfoList.count == 0 {
            return
        }
        pickerV.reloadAllComponents()
        currentSelect()
    }
    
    ///获取当前的选择项
    public func getCurrentSelect() -> [PickerSelectInfo] {
        var selList:[PickerSelectInfo] = Array()
        if linkage {
            if let list = pickerShowInfoList.first {
                var currList:[PickerShowInfo]? = list
                for i in 0..<pickerV.numberOfComponents {
                    let selRow = pickerV.selectedRow(inComponent: i)
                    let selInfo:PickerShowInfo?
                    if let currL = currList, currL.count > selRow{
                        selInfo = currL[selRow]
                        currList = selInfo?.subList
                    }else{
                        selInfo = nil
                    }
                    selList.append(PickerSelectInfo.init(selInfo, index: selRow))
                }
            }
        }else{
            for i in 0..<pickerShowInfoList.count {
                let list = pickerShowInfoList[i];
                let selectRow = pickerV.selectedRow(inComponent: i)
                selList.append(PickerSelectInfo.init(list[selectRow], index: selectRow))
            }
        }
        return selList
    }
    
    ///当前的选择项
    public func currentSelect() {
        let selList = getCurrentSelect()
        if selList.count > 0 {
            selectClosure?(selList)
        }
    }
    
}

/// 以下所设置均假设上面几个参数设定时正确的
extension UIPickerManager : UIPickerViewDelegate, UIPickerViewDataSource {
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if linkage {
            return Int(min(linkageNumber, 3))
        } else {
            return pickerShowInfoList.count
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if linkage {
            if pickerShowInfoList.count == 0{
                return 0;
            }
            let list = pickerShowInfoList.first;
            switch component {
            case 0: /// 第一层
                return list?.count ?? 0
            case 1: /// 第二层
                if let list = list, list.count > 0  {
                    let oneRow = pickerView.selectedRow(inComponent: 0)
                    //                    let oneRow  = selectedRows[0]
                    let PickerShowInfo = list[oneRow]
                    return PickerShowInfo.subList?.count ?? 0
                }else{
                    return 0
                }
            case 2: /// 第三层
                if let list = list, list.count > 0 {
                    let oneRow = pickerView.selectedRow(inComponent: 0)
                    //                    let oneRow = selectedRows[1]
                    let oneInfo = list[Int(oneRow)]
                    if let subList = oneInfo.subList , subList.count > 0 {
                        let twoRow = pickerView.selectedRow(inComponent: 1)
                        if twoRow < subList.count{
                            let twoInfo = subList[twoRow]
                            MessageInfo.print("===========第三层的数据==========" + String(twoInfo.subList?.count ?? 0))
                            return twoInfo.subList?.count ?? 0
                        }
                        return 0
                    }else{
                        return 0
                    }
                }else{
                    return 0
                }
            default:
                return 0
            }
        } else {
            let list = pickerShowInfoList[component];
            return list.count
        }
    }
    
    
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let showV = UIView.init()
        let titleL = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: 1, height: 1))
        titleL.font =  .MSystemFont(16, .medium)
        titleL.textColor = .black
        titleL.textAlignment = .center
        showV.addSubview(titleL)
        titleL.snp.makeConstraints { make in
            make.edges.equalTo(showV)
        }
        var showString:String!
        if linkage {
            if let list = pickerShowInfoList.first, list.count > 0 {
                switch component {
                case 0: /// 第一层
                    if list.count > row {
                        let picInfo = list[row]
                        showString = picInfo.showStr
                    }else{
                        showString = ""
                    }
                case 1: /// 第二层
                    let selOnePicInfo = list[pickerView.selectedRow(inComponent: 0)]
                    if let subList = selOnePicInfo.subList, subList.count > row {
                        let picInfo = subList[row]
                        showString = picInfo.showStr
                    }else{
                        showString = ""
                    }
                case 2: /// 第三层
                    let selOnePicInfo = list[pickerView.selectedRow(inComponent: 0)]
                    let selTwoRow = pickerView.selectedRow(inComponent: 1)
                    if let twoList = selOnePicInfo.subList, twoList.count > selTwoRow {
                        let selTwoPicInfo = twoList[selTwoRow]
                        if selTwoPicInfo.subList?.count ?? 0 > row {
                            let picInfo = selTwoPicInfo.subList?[row]
                            showString = picInfo?.showStr
                        }else{
                            showString = ""
                        }
                    }else{
                        showString = ""
                    }
                default:
                    showString = ""
                }
            }else{
                showString = ""
            }
        } else {
            let list = pickerShowInfoList[component];
            let picInfo = list[row]
            showString = picInfo.showStr
        }
        titleL.text = showString
        for view in pickerView.subviews{
            view.backgroundColor = .clear
        }
        return showV
    }
    
    
    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30.0
    }
    
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if linkage {
            switch component {
            case 0:
                if pickerView.numberOfComponents > 1{
                    pickerView.reloadComponent(1)
                    let maxNum = pickerView.numberOfRows(inComponent: 1)
                    var seletNum = pickerView.selectedRow(inComponent: 1)
                    if (defailtInitSelectNum?.count ?? 0) > 1 , let num = defailtInitSelectNum?[1] as? UInt {
                        seletNum = Int(num)
                    }
                    pickerView.selectRow(min(((maxNum > 0) ? (maxNum - 1) : 0), seletNum), inComponent: 1, animated: false)
                    
                    if pickerView.numberOfComponents > 2{
                        pickerView.reloadComponent(2)
                        let max2Num = pickerView.numberOfRows(inComponent: 2)
                        var selet2Num = pickerView.selectedRow(inComponent: 2)
                        if (defailtInitSelectNum?.count ?? 0) > 2 , let num = defailtInitSelectNum?[2] as? UInt {
                            selet2Num = Int(num)
                        }
                        pickerView.selectRow(min(((max2Num > 0) ? (max2Num - 1) : 0), selet2Num), inComponent: 2, animated: false)
                    }
                }
            case 1:
                if pickerView.numberOfComponents > 2{
                    pickerView.reloadComponent(2)
                    let maxNum = pickerView.numberOfRows(inComponent: 2)
                    var seletNum = pickerView.selectedRow(inComponent: 2)
                    if (defailtInitSelectNum?.count ?? 0) > 2 , let num = defailtInitSelectNum?[2] as? UInt {
                        seletNum = Int(num)
                    }
                    pickerView.selectRow(min(((maxNum > 0) ? (maxNum - 1) : 0), seletNum), inComponent: 2, animated: false)
                }
            default:
                print(#file,"123___default")
            }
        }
                  
        currentSelect()

    }
    
    
}
