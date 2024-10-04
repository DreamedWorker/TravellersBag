//
//  ColorfulText.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/4.
//

import Foundation
import AppKit

func colorfulString(from string: String) -> NSAttributedString {
    let pattern = "<color=(#.*?)>(.*?)</color>"
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    // 查找匹配项
    let matches = regex.matches(in: string, range: NSRange(string.startIndex..., in: string))
    let attributedString = NSMutableAttributedString()
    // 添加未被标记的部分
    var unmarkedStart = string.startIndex
    for match in matches {
        if let rangeStart = Range(match.range, in: string) {
            let rangeBeforeTag = string[unmarkedStart..<rangeStart.lowerBound]
            if !rangeBeforeTag.isEmpty {
                attributedString.append(NSAttributedString(string: String(rangeBeforeTag)))
            }
            if let rangeColor = Range(match.range(at: 1), in: string),
               let rangeText = Range(match.range(at: 2), in: string) {
                let colorValue = String(string[rangeColor])
                let textBetweenTags = String(string[rangeText])
                // 解析颜色值
                let color = NSColor(hexString: colorValue)
                // 创建带有颜色属性的NSAttributedString
                let attributedText = NSAttributedString(string: textBetweenTags, attributes: [NSAttributedString.Key.foregroundColor: color])
                // 添加带颜色属性的文本
                attributedString.append(attributedText)
            }
            unmarkedStart = string.index(after: rangeStart.upperBound)
        }
    }
    // 添加最后一个未被标记的部分
    let lastPart = string[unmarkedStart..<string.endIndex]
    if !lastPart.isEmpty {
        attributedString.append(NSAttributedString(string: String(lastPart)))
    }
    return attributedString
}

extension NSColor {
    convenience init(hexString: String) {
        var cString = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        let red = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
        let green = CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0
        let blue = CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0
        let alpha = CGFloat((rgbValue & 0x000000FF) >> 0) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
