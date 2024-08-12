//
//  Announcement.swift
//  TravellingBag
//
//  Created by 鸳汐 on 2024/8/2.
//

import Foundation

/// 定义启动器内显示的公告内容模型
class Announcement : Identifiable {
    var annId: Int
    var title: String
    var subtitle: String //这里也有个槽点，在显示的时候其实subtitle的东西才是title
    var typeLabel: String
    var tagLabel: String
    var banner: String?
    
    init(annId: Int, title: String, subtitle: String, typeLabel: String, tagLabel: String, banner: String? = nil) {
        self.annId = annId
        self.title = title
        self.subtitle = subtitle
        self.typeLabel = typeLabel
        self.tagLabel = tagLabel
        self.banner = banner
    }
    
    //未来这个方法或许会有用？
    func forStorage() -> String {
        return "\(annId)&\(title)&\(subtitle)&\(typeLabel)&\(tagLabel)&\(banner ?? "default")"
    }
}
