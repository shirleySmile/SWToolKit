//
//  UIView+Frame.swift
//  SWToolKit
//
//  Created by shirley on 2022/5/17.
//

import Foundation
import UIKit

extension UIView{
     
    public var x:CGFloat {
        get{ return frame.origin.x }
        set(newValue){
            var tempFrame :CGRect = frame
            tempFrame.origin.x = newValue
            frame = tempFrame
        }
    }
    
    public var y:CGFloat {
        get{ return frame.origin.y }
        set(newValue){
            var tempFrame :CGRect = frame
            tempFrame.origin.y = newValue
            frame = tempFrame
        }
    }
    
    public var width:CGFloat {
        get{ return frame.size.width }
        set(newValue){
            var tempFrame :CGRect = frame
            tempFrame.size.width = newValue
            frame = tempFrame
        }
    }
    
    public var height:CGFloat {
        get{ return frame.size.height }
        set(newValue){
            var tempFrame :CGRect = frame
            tempFrame.size.height = newValue
            frame = tempFrame
        }
    }
    
    public var size:CGSize {
        get{ return frame.size }
        set(newValue){
            var tempFrame :CGRect = frame
            tempFrame.size = newValue
            frame = tempFrame
        }
    }
    
    public var centerX:CGFloat {
        get{ return center.x }
        set(newValue){
            var tempCenter:CGPoint = center
            tempCenter.x = newValue
            center = tempCenter
        }
    }
    
    public var centerY:CGFloat {
        get{ return center.y }
        set(newValue){
            var tempCenter:CGPoint = center
            tempCenter.y = newValue
            center = tempCenter
        }
    }
    
    public var maxX:CGFloat {
        get{ return frame.maxX }
        set{}
    }
    
    public var maxY:CGFloat {
        get{ return frame.maxY }
        set{}
    }
    
    public var origin:CGPoint{
        get{ return frame.origin }
        set(newValue){
            var tempFrame :CGRect = frame
            tempFrame.origin = newValue
            frame = tempFrame
        }
    }
}
