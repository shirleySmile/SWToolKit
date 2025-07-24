//
//  BaseView.swift
//  SWToolKit
//
//  Created by shirley on 2022/5/18.
//

import Foundation
import UIKit

///  点击穿透的view
open class HitThroughView: UIView {
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitV = super.hitTest(point, with: event)
        if hitV == self {
            return nil
        }
        return hitV
    }
    
}

