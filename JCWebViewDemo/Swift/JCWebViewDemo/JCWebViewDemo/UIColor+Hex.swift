//
//  UIColor+Hex.swift
//
//

import Foundation
import UIKit

public extension String {
    func hexValue() -> Int {
        var hexInt:UInt32 = 0
        Scanner(string: self).scanHexInt32(&hexInt)
        return Int(hexInt)
    }
}

extension UIColor {
    public class func color(withHex hexColor:Int, alpha: CGFloat = 1) -> UIColor {
        let red = CGFloat( (hexColor & 0xFF0000) >> 16 ) / 255.0;
        let green = CGFloat( (hexColor & 0xFF00) >> 8 ) / 255.0;
        let blue = CGFloat( (hexColor & 0xFF) ) / 255.0;
        return UIColor.init(red: red, green: green, blue: blue, alpha: alpha);
    }
    
    public class func colorOfHexText(_ hexText:String) -> UIColor {
        var hexString:String = hexText
        if hexText.hasPrefix("#") {
            let startIndex = hexText.index(hexText.startIndex, offsetBy: 1)
            hexString = hexText.substring(from: startIndex)
        }
        let colorHex:Int = hexString.hexValue()
        return UIColor.color(withHex: colorHex, alpha: 1)
    }
}



