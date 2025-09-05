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
    enum WaterMarkCorner {
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



extension UIImage {
    
    // 修复图片旋转
    func fixOrientation() -> UIImage{
        if self.imageOrientation == .up{
            return self
        }
        var transform = CGAffineTransform.identity
        
        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x:self.size.width, y:self.size.height)
            transform = transform.rotated(by: .pi)
            break
            
        case .left, .leftMirrored:
            transform = transform.translatedBy(x:self.size.width, y:0)
            transform = transform.rotated(by: .pi/2)
            break
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x:0, y:self.size.height)
            transform = transform.rotated(by: -.pi/2)
            break
            
        default:
            break
        }
        
        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x:self.size.width, y:0)
            transform = transform.scaledBy(x:-1, y:1)
            break
            
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x:self.size.height, y:0);
            transform = transform.scaledBy(x:-1, y:1)
            break
        default:
            break
        }
        
        let ctx = CGContext(data:nil, width:Int(self.size.width), height:Int(self.size.height), bitsPerComponent:self.cgImage!.bitsPerComponent, bytesPerRow:0, space:self.cgImage!.colorSpace!, bitmapInfo:self.cgImage!.bitmapInfo.rawValue)
        ctx?.concatenate(transform)
        
        switch self.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx?.draw(self.cgImage!, in:CGRect(x:CGFloat(0), y:CGFloat(0), width:CGFloat(size.height), height:CGFloat(size.width)))
            break
            
        default:
            ctx?.draw(self.cgImage!, in:CGRect(x:CGFloat(0), y:CGFloat(0), width:CGFloat(size.width), height:CGFloat(size.height)))
            break
        }
        
        let cgimg:CGImage = (ctx?.makeImage())!
        let img = UIImage(cgImage: cgimg)
        
        return img
    }
    
    
}



// MARK: 压缩图片
extension UIImage {
    
    
    /// 改变图片的尺寸
    public func scale(newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext();
        return newImage
    }
    
    /// 仅改变图片的尺寸
    func resize(to newSize: CGSize) -> UIImage {
        guard (self.size.width > newSize.width && self.size.height > newSize.height) else {
            return self
        }
        
        let format = UIGraphicsImageRendererFormat()
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}



//MARK: 给图片加描边
extension UIImage {
    
    /// Applies a stroke around the image
    /// - Parameters:
    ///   - strokeColor: The color of the desired stroke
    ///   - inputThickness: The thickness, in pixels, of the desired stroke
    ///   - rotationSteps: The number of rotations to make when applying the stroke. Higher rotationSteps will result in a more precise stroke. Defaults to 8.
    ///   - extrusionSteps: The number of extrusions to make along a given rotation. Higher extrusions will make a more precise stroke, but aren't usually needed unless using a very thick stroke. Defaults to 1.
    func applyingStroke(color strokeColor: UIColor, width inputThickness: CGFloat, rotation: Int? = nil, extrusion: Int? = nil) -> UIImage {
        //        let thickness: CGFloat = inputThickness > 0 ? inputThickness : 0
        let thickness: CGFloat = inputThickness
        guard thickness > 0 else {
            return self
        }
        let rotationSteps:Int = rotation ?? min(max(Int(inputThickness * 2), 12), 30)
        let extrusionSteps:Int = extrusion ?? 1
        // Create a "stamp" version of ourselves that we can stamp around our edges
        let strokeImage = imageByFillingWithColor(strokeColor)
        let inputSize: CGSize = size
        let outputSize: CGSize = CGSize(width: size.width + (thickness * 2), height: size.height + (thickness * 2))
        let renderer = UIGraphicsImageRenderer(size: outputSize)
        let stroked = renderer.image { ctx in
            // Compute the center of our image
            let center = CGPoint(x: outputSize.width / 2, y: outputSize.height / 2)
            let centerRect = CGRect(x: center.x - (inputSize.width / 2), y: center.y - (inputSize.height / 2), width: inputSize.width, height: inputSize.height)
            // Compute the increments for rotations / extrusions
            let rotationIncrement: CGFloat = rotationSteps > 0 ? 360 / CGFloat(rotationSteps) : 360
            let extrusionIncrement: CGFloat = extrusionSteps > 0 ? thickness / CGFloat(extrusionSteps) : thickness
            for rotation in 0..<rotationSteps {
                for extrusion in 1...extrusionSteps {
                    // Compute the angle and distance for this stamp
                    let angleInDegrees: CGFloat = CGFloat(rotation) * rotationIncrement
                    let angleInRadians: CGFloat = angleInDegrees * .pi / 180.0
                    let extrusionDistance: CGFloat = CGFloat(extrusion) * extrusionIncrement
                    // Compute the position for this stamp
                    let x = center.x + extrusionDistance * cos(angleInRadians)
                    let y = center.y + extrusionDistance * sin(angleInRadians)
                    let vector = CGPoint(x: x, y: y)
                    // Draw our stamp at this position
                    let drawRect = CGRect(x: vector.x - (inputSize.width / 2), y: vector.y - (inputSize.height / 2), width: inputSize.width, height: inputSize.height)
                    strokeImage.draw(in: drawRect, blendMode: .destinationOver, alpha: 1.0)
                }
            }
            // Finally, re-draw ourselves centered within the context, so we appear in-front of all of the stamps we've drawn
            self.draw(in: centerRect, blendMode: .normal, alpha: 1.0)
        }
        return stroked
    }
    
    
    /// Returns a version of this image any non-transparent pixels filled with the specified color
    /// - Parameter color: The color to fill
    /// - Returns: A re-colored version of this image with the specified color
    private func imageByFillingWithColor(_ color: UIColor) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.fill(context.format.bounds)
            draw(in: context.format.bounds, blendMode: .destinationIn, alpha: 1.0)
        }
    }
    
}



//MARK: 生成背景图片
extension UIImage {
    
    /// 渐变色图片
    public static func gradient(with imgSize:CGSize, colors: [UIColor], start startPoint: CGPoint = CGPoint(x: 0, y: 0.5), end endPoint: CGPoint = CGPoint(x: 1, y: 0.5)) -> UIImage? {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: .zero, size: imgSize)
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        
        return UIGraphicsImageRenderer(size: imgSize).image { context in
            gradientLayer.render(in: context.cgContext)
        }
    }
    
    /// 以圆心向外渐变色图片
    public static func radialGradient(with imgSize:CGSize, colors:[UIColor]) -> UIImage? {
        let cgColors = colors.map { $0.cgColor } as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let scale:CGFloat = 1.0 / CGFloat(colors.count-1)
        var locations: [CGFloat] = Array()
        for idx in 0..<(colors.count-1) {
            locations.append(CGFloat(idx) * scale)
        }
        locations.append(1.0)
        if let gradient = CGGradient(colorsSpace: colorSpace,
                                     colors: cgColors,
                                     locations: locations) {
            let center = CGPoint(x: imgSize.width/2.0, y: imgSize.height/2.0)
            let radius = max(imgSize.width, imgSize.height) / 2
            
            return UIGraphicsImageRenderer(size: imgSize).image { context in
                context.cgContext.drawRadialGradient(gradient,
                                                     startCenter: center,
                                                     startRadius: 0,
                                                     endCenter: center,
                                                     endRadius: radius,
                                                     options: .drawsAfterEndLocation)
            }
            
        }
        return nil
    }
    
    
}






