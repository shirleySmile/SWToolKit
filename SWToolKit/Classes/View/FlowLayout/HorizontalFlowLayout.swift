//
//  HorizontalFlowLayout.swift
//  SWToolKit
//
//  Created by shirley on 2022/3/10.
//

import Foundation
import UIKit


///横向分页collectionview layout
public class HorizontalFlowLayout:UICollectionViewFlowLayout {
    
    public var rowOfPage:Int = 0;//一页行数
    public var columnOfPage:Int = 0;//一页列数
    
    fileprivate var pageNum = 0;
    
    //所有cell的布局属性
    var layoutAttributes: [UICollectionViewLayoutAttributes] = [UICollectionViewLayoutAttributes]();
    
    public override init() {
        super.init();
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //计算布局
    public override func prepare() {
        
        guard rowOfPage > 0 && columnOfPage > 0 else {
            print("必须设置rowOfPage和columnOfPage")
            return
        }
        collectionView?.isPagingEnabled = true;
        layoutAttributes.removeAll();
                
        ///只取第一组 --- 必须方后面 前面设置基础数据
        let itemNum: Int = self.collectionView!.numberOfItems(inSection: 0)
        
        pageNum = (itemNum-1)/(rowOfPage*columnOfPage)
        
        for j in 0..<itemNum{
            let layout = self.layoutAttributesForItem(at: IndexPath(item: j, section: 0))
            layout != nil ? self.layoutAttributes.append(layout!) : nil;
        }
    }
    
    
    /**
     返回true只要显示的边界发生改变就重新布局:(默认是false)
     内部会重新调用prepareLayout和调用
     layoutAttributesForElementsInRect方法获得部分cell的布局属性
     */
    
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true;
    }
    
    
    /*
     根据indexPath去对应的UICollectionViewLayoutAttributes  这个是取值的，要重写，在移动删除的时候系统会调用改方法重新去UICollectionViewLayoutAttributes然后布局
     */
    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        let layoutAttribute = super.layoutAttributesForItem(at: indexPath);
        
        if layoutAttribute != nil {
            
            ///获取当前item位于第几页 第几行 第几个
            
            ///第几行 = 当前数/每行几个
            let itemRow = indexPath.item/columnOfPage
            ///第几列 = 当前数&每行几个
            let itemColumn = indexPath.item%columnOfPage
            ///第几页
            let itemPage = indexPath.item/(rowOfPage*columnOfPage)
            
            
            let cViewW = (collectionView?.frame.width ?? 0.0) - self.sectionInset.left - self.sectionInset.right
            let cViewH = (collectionView?.frame.height ?? 0.0) - self.sectionInset.top - self.sectionInset.bottom
            
            let itemW = (cViewW - CGFloat(columnOfPage - 1) * self.minimumInteritemSpacing) / CGFloat(columnOfPage)
            let itemH = (cViewH - CGFloat(rowOfPage - 1) * self.minimumLineSpacing) / CGFloat(rowOfPage)
            
            let itemSize = CGSize(width: itemW, height: itemH)
            
            
            
            let point_x = (collectionView?.frame.width ?? 0.0) * CGFloat(itemPage) + self.sectionInset.left
            ///计算x的位置
            let frame_x = point_x + (itemSize.width + self.minimumInteritemSpacing) * CGFloat(itemColumn)
            
            //计算y的位置
            let frame_y = self.sectionInset.top + (itemSize.height + self.minimumLineSpacing) * CGFloat(itemRow%rowOfPage)
            ///设置frame
            layoutAttribute?.frame = CGRect(x:frame_x, y:frame_y, width: itemSize.width, height: itemSize.height);

            return layoutAttribute;
        }

        return nil
    }
    
    
    override open var collectionViewContentSize: CGSize {
        
        return CGSize(width: (self.collectionView?.frame.width)! * CGFloat(pageNum+1), height: self.collectionView!.frame.height);
    }
    
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        return self.layoutAttributes
    }
    

}
