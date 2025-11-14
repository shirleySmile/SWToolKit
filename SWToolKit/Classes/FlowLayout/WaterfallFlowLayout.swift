//
//  WaterFallFlowLayout.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/10.
//

import UIKit

@objc public protocol WaterfallFlowLayoutDelegate: NSObjectProtocol {
    
    /// item的高度
    func waterFlowLayout_itemHeight(_ layout: WaterfallFlowLayout, indexPath: IndexPath) -> CGFloat
    /// collection列数
    @objc optional func waterFallLayout_columnCount(_ layout:WaterfallFlowLayout) -> Int
    /// 每列之间的间距
    @objc optional func WaterFallLayout_columnMargin(_ layout:WaterfallFlowLayout) -> CGFloat
    /// 每行之间的间距
    @objc optional func WaterFallLayout_rowMargin(_ layout:WaterfallFlowLayout) -> CGFloat
    ///每个item的内边距
    @objc optional func WaterFallLayout_itemEdgeInsetd(_ layout:WaterfallFlowLayout) -> UIEdgeInsets
}

public class WaterfallFlowLayout: UICollectionViewFlowLayout {
    
    public weak var delegate: WaterfallFlowLayoutDelegate?
    
    ///默认设置
    var defultColunmCount :Int = 2 //列数
    var defultColunmMargin :CGFloat = 5.0 //列间距
    var defultRowMargin :CGFloat = 5.0 //行间距
    var defultEdgeInsets :UIEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0) //item内边距
    
    // 布局数组
    lazy var layoutAttributeArray: [UICollectionViewLayoutAttributes] = [UICollectionViewLayoutAttributes]()
    // 高度数组
    lazy var maxY_Array: [CGFloat] = Array(repeating: self.sectionInset.top, count: self.get_colunmCount())
    fileprivate var startIndex:Int = 0
    
    
    func get_colunmCount() -> Int {
        return self.delegate?.waterFallLayout_columnCount?(self) ?? defultColunmCount
    }
    func get_columnMargin() -> CGFloat {
        return self.delegate?.WaterFallLayout_columnMargin?(self) ?? defultColunmMargin
    }
    func get_rowMargin() -> CGFloat {
        return self.delegate?.WaterFallLayout_rowMargin?(self) ?? defultRowMargin
    }
    func get_itemEdgeInsets() -> UIEdgeInsets {
        return self.delegate?.WaterFallLayout_itemEdgeInsetd?(self) ?? defultEdgeInsets
    }
    

    public override func prepare() {
        super.prepare()
      
        let collectionW : CGFloat = collectionView!.bounds.size.width;
        let itemCount :Int = collectionView!.numberOfItems(inSection: 0)//item个数
        
        let total_colNum  :Int          = get_colunmCount()//每列个数
        let edgeInset     :UIEdgeInsets = get_itemEdgeInsets()//item内边距
        let column_margin :CGFloat      = get_columnMargin()//每列间隙
        let row_margin    :CGFloat      = get_rowMargin()//每行间隙
        let itemW = (collectionW-edgeInset.left-edgeInset.right-CGFloat((total_colNum-1))*column_margin)/CGFloat(Float(total_colNum))
         
        // 设置每一列默认的高度
        for i in 0..<total_colNum {
            self.maxY_Array[i] = self.headerReferenceSize.height
        }

        //header
        let layoutHeader = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with:IndexPath.init(row: 0, section: 0))
        layoutHeader.frame = CGRect.init(x: 0, y: 0, width: self.headerReferenceSize.width, height: self.headerReferenceSize.height)
        if layoutAttributeArray.count > 0{
            layoutAttributeArray[0] = layoutHeader
        }else{
            layoutAttributeArray.append(layoutHeader)
        }
        startIndex = 0
    
        //创建指定个数的atts
        for i in startIndex..<itemCount {
            //计算indexPath
            let indexPath = IndexPath(item: i, section: 0)
            //创建atts
            let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            let itemH :CGFloat = (delegate?.waterFlowLayout_itemHeight(self, indexPath: indexPath)) ?? 0.0
            let height:CGFloat = self.maxY_Array.min()!
            
            let index  = self.maxY_Array.firstIndex(of: height)!
            let itemX  = edgeInset.left + (itemW + column_margin)*CGFloat(index)
            let itemY:CGFloat = height + row_margin
              
            //设置attr的frame
            attr.frame = CGRect(x: itemX, y: itemY, width: itemW, height: itemH)
            //保存heights
            self.maxY_Array[index] = height + row_margin + itemH
            //保存frame
            layoutAttributeArray.append(attr)
        }
        //记录当前最大的count
        startIndex = itemCount
        
    }
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return layoutAttributeArray
    }
    
    public override var collectionViewContentSize: CGSize{
        return CGSize(width: 0, height:maxY_Array.max() ?? 0 + get_rowMargin())
    }
}

 
 
