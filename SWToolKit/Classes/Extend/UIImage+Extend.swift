//
//  UIImageExtend.swift
//  SWToolKit
//
//  Created by shirley on 2022/2/26.
//

import Foundation
import UIKit

/// 与UIImage相关的方法
extension UIImage {
    
    
    /// 改变图片的尺寸
    public func scale(newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext();
        return newImage
    }
    
    
    /// 通过颜色创建图片
    /// - Parameter color: 颜色值
    /// - Returns: 图片
    public static func initWith(color: UIColor,_ size:CGSize = .init(width: 1, height: 1)) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
    
    /// 截切图片
    /// - Parameters:
    ///   - cgImage: 原始图片
    ///   - originalRect: 裁切尺寸
    ///   - multiple: 图片比例
    /// - Returns: 结果
    public func cuttingImage(originalRect:CGRect, multiple: CGFloat) -> UIImage {
        guard let cgImage = self.cgImage else{
            return .initWith(color: UIColor.clear, originalRect.size)
        }
        let cropRect = CGRect(x:originalRect.origin.x * CGFloat(multiple),
                              y:originalRect.origin.y * CGFloat(multiple),
                              width: originalRect.size.width * CGFloat(multiple),
                              height: originalRect.size.height * CGFloat(multiple))
        
        
        
        let newImageRef = cgImage.cropping(to: cropRect)
        if newImageRef != nil{
            return UIImage.init(cgImage: newImageRef!)
        }
        return .initWith(color: UIColor.clear, originalRect.size)
    }
    
    
    /// 获取模糊图
    /// level 0~1
    public func getBlurImage(level: Float) -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        
        let tempLevel:Float = min(max(0, level), 1.0)
        
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        let tempR = tempLevel*100.0
        filter?.setValue(tempR, forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    
    
    /// 图片切圆角
    /// - Parameters:
    ///   - byRoundingCorners: 圆角方向
    ///   - cornerRadi: 半径
    /// - Returns: 返回图片
    public func roundImage(byRoundingCorners: UIRectCorner = UIRectCorner.allCorners, cornerRadi: CGFloat) -> UIImage? {
        return roundImage(byRoundingCorners: byRoundingCorners, cornerRadii: CGSize(width: cornerRadi, height: cornerRadi))
    }
    
    func roundImage(byRoundingCorners: UIRectCorner = UIRectCorner.allCorners, cornerRadii: CGSize) -> UIImage? {
        
        let imageRect = CGRect(origin: CGPoint.zero, size:self.size )
        UIGraphicsBeginImageContextWithOptions(self.size, false, scale)
        defer {
            UIGraphicsEndImageContext()
        }
        let context = UIGraphicsGetCurrentContext()
        guard context != nil else {
            return nil
        }
        context?.setShouldAntialias(true)
        let bezierPath = UIBezierPath(roundedRect: imageRect,
                                      byRoundingCorners: byRoundingCorners,
                                      cornerRadii: cornerRadii)
        bezierPath.close()
        bezierPath.addClip()
        self.draw(in: imageRect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 二维码
    public static func creatQRCodeImage(text: String,WH:CGFloat) -> UIImage{
        
        //创建滤镜
        let filter = CIFilter(name: "CIQRCodeGenerator")
        //还原滤镜的默认属性
        filter?.setDefaults()
        //设置需要生成二维码的数据
        filter?.setValue(text.data(using: String.Encoding.utf8), forKey: "inputMessage")
        //从滤镜中取出生成的图片
        let ciImage = filter?.outputImage
        //这个清晰度好
        let bgImage = createNonInterpolatedUIImageFormCIImage(image: ciImage!, size: WH)
        
        return bgImage
    }
    
    private static func createNonInterpolatedUIImageFormCIImage(image: CIImage, size: CGFloat) -> UIImage {
        
        let extent: CGRect = image.extent.integral
        let scale: CGFloat = min(size/extent.width, size/extent.height)
        
        let width = extent.width * scale
        let height = extent.height * scale
        let cs: CGColorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapRef = CGContext(data: nil,  width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: 0)!
        
        let context = CIContext(options: nil)
        let bitmapImage: CGImage = context.createCGImage(image, from: extent)!
        
        bitmapRef.interpolationQuality = CGInterpolationQuality.none
        bitmapRef.scaleBy(x: scale, y: scale)
        bitmapRef.draw(bitmapImage, in: extent)
        let scaledImage: CGImage = bitmapRef.makeImage()!
        return UIImage(cgImage: scaledImage)
        
    }
    
    
    /**
     绘制图片
     
     @param color 背景色
     @param size 大小
     @param text 文字
     @param textAttributes 字体设置
     @param isCircular 是否圆形
     @return 图片
     */
    public static func drawImage(color:UIColor = .black,size:CGSize,text:String,font:UIFont,attri:[NSAttributedString.Key : Any]?,isCircular:Bool = false) -> UIImage{
        if size.width <= 0 || size.height <= 0{
            return UIImage()
        }
        let rect = CGRect.init(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        if isCircular{
            let path = CGPath(ellipseIn: rect, transform: nil)
            context?.addPath(path)
            context?.clip()
        }
        context?.setFillColor(color.cgColor)
        context?.fill([rect])
        
        // text
        let textSize = text.size(width: MAXFLOAT, font: font)
        text.draw(in: CGRect(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2, width: textSize.width, height: textSize.height), withAttributes: attri)
        
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
        
    }
    
    
    //水印位置枚举
    enum WaterMarkCorner{
        case TopLeft
        case TopRight
        case BottomLeft
        case BottomRight
    }
    
    //添加水印方法
    func waterMarkedImage(waterMarkText:String, corner:WaterMarkCorner = .BottomRight, margin:CGPoint = CGPoint(x: 20, y: 20), waterMarkTextColor:UIColor = .white,
                          waterMarkTextFont:UIFont = .systemFont(ofSize:20),
                          backgroundColor:UIColor = .clear) -> UIImage{
        
        let attrStr = NSAttributedString(string: waterMarkText, attributes: [.foregroundColor:waterMarkTextColor,.font:waterMarkTextFont])
        
        let textSize = attrStr.size()
        var textFrame = CGRectMake(0, 0, textSize.width, textSize.height)
        
        let imageSize = self.size
        switch corner{
        case .TopLeft:
            textFrame.origin = margin
        case .TopRight:
            textFrame.origin = CGPoint(x: imageSize.width - textSize.width - margin.x, y: margin.y)
        case .BottomLeft:
            textFrame.origin = CGPoint(x: margin.x, y: imageSize.height - textSize.height - margin.y)
        case .BottomRight:
            textFrame.origin = CGPoint(x: imageSize.width - textSize.width - margin.x,
                                       y: imageSize.height - textSize.height - margin.y)
        }
        
        // 开始给图片添加文字水印
        UIGraphicsBeginImageContextWithOptions(imageSize, false, self.scale)
        self.draw(in: .init(origin: .zero, size: imageSize))
        attrStr.draw(in: textFrame)
        let waterMarkedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return waterMarkedImage!
        
    }
    
}



