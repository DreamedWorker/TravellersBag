//
//  UIGF4.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/27.
//

import Foundation

struct Info : Encodable {
    var export_timestamp: Int // 导出档案的时间戳，秒级
    var export_app: String = "旅者行囊" //导出档案的 App 名称
    var export_app_version: String = "0.0.1(20240908)" // 导出档案的 App 版本
    var version: String = "v4.0" // 导出档案的 UIGF 版本号
}

struct SingleGachaItem: Encodable {
    var uigf_gacha_type: String // UIGF 卡池类型
    var gacha_type: String // 卡池类型
    var item_id: String // 物品的内部 ID
    var time: String // 抽取物品时对应时区（timezone）下的当地时间
    var id: String // 记录内部 ID
}

struct HK4E: Encodable {
    var uid: String
    var timezone: Int = 0
    var list: [SingleGachaItem]
}

struct UIGFFile : Encodable {
    var info: Info
    var hk4e: [HK4E]
}
