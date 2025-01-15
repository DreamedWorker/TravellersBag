//
//  UIAF11.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/28.
//

import Foundation

struct UIAFInfo: Encodable {
    var export_timestamp: Int // 导出档案的时间戳，秒级
    var export_app: String = "旅者行囊" //导出档案的 App 名称
    var export_app_version: String = "0.0.3(20241024)" // 导出档案的 App 版本
    var uiaf_version: String = "v1.1" // 导出档案的 UIAF 版本号
}

struct UIAFUnit: Encodable {
    var id: Int
    var timestamp: Int
    var current: Int
    var status: Int
}

struct UIAFFile: Encodable {
    var info: UIAFInfo
    var list: [UIAFUnit]
}
