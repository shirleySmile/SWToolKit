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
    
    // 布局数组（每次 prepare 时重建）
    var layoutAttributeArray: [UICollectionViewLayoutAttributes] = []
    // 每列当前的最大 Y（每次 prepare 时按当前列数重建）
    var maxY_Array: [CGFloat] = []
    
    
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
        
        guard let collectionView = collectionView else { return }
        let collectionW : CGFloat = collectionView.bounds.size.width;
        let itemCount :Int = collectionView.numberOfItems(inSection: 0)//item个数
        
        let total_colNum  :Int          = get_colunmCount()//每列个数
        
        /// 先清空旧布局再判断列数，避免列数<=0 提前返回时残留旧属性（旧 cell 不清空、contentSize 过期）
        layoutAttributeArray.removeAll()
        maxY_Array.removeAll()
        guard total_colNum > 0 else { return }
        
        let edgeInset     :UIEdgeInsets = get_itemEdgeInsets()//item内边距
        let column_margin :CGFloat      = get_columnMargin()//每列间隙
        let row_margin    :CGFloat      = get_rowMargin()//每行间隙
        let itemW = max(0, (collectionW-edgeInset.left-edgeInset.right-CGFloat((total_colNum-1))*column_margin)/CGFloat(total_colNum))
         
        /// 每列初始高度按当前列数重建，防止 delegate 列数变化后数组长度不匹配导致越界
        maxY_Array = Array(repeating: self.headerReferenceSize.height + edgeInset.top, count: total_colNum)

        //header
        let layoutHeader = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with:IndexPath.init(row: 0, section: 0))
        layoutHeader.frame = CGRect.init(x: 0, y: 0, width: self.headerReferenceSize.width, height: self.headerReferenceSize.height)
        layoutAttributeArray.append(layoutHeader)
    
        //创建指定个数的atts
        for i in 0..<itemCount {
            //计算indexPath
            let indexPath = IndexPath(item: i, section: 0)
            //创建atts
            let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            let itemH :CGFloat = (delegate?.waterFlowLayout_itemHeight(self, indexPath: indexPath)) ?? 0.0
            let height:CGFloat = self.maxY_Array.min() ?? 0
            
            let index  = self.maxY_Array.firstIndex(of: height) ?? 0
            let itemX  = edgeInset.left + (itemW + column_margin)*CGFloat(index)
            let itemY:CGFloat = height + row_margin
              
            //设置attr的frame
            attr.frame = CGRect(x: itemX, y: itemY, width: itemW, height: itemH)
            //保存heights
            self.maxY_Array[index] = height + row_margin + itemH
            //保存frame
            layoutAttributeArray.append(attr)
        }
    }
    
    /// 按 indexPath 精确返回瀑布流属性（UIKit 增删 item 的动画依赖此方法，父类默认实现与瀑布流坐标不一致）
    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributeArray.first { $0.indexPath == indexPath && $0.representedElementCategory == .cell }
    }
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        /// 只返回与显示区域相交的属性，避免返回全量属性造成滚动性能问题
        return layoutAttributeArray.filter { $0.frame.intersects(rect) }
    }
    
    public override var collectionViewContentSize: CGSize{
        return CGSize(width: 0, height: (maxY_Array.max() ?? 0) + get_rowMargin() + get_itemEdgeInsets().bottom)
    }
}

  
