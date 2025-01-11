//
//  HouseCell.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/14.
//

import Foundation

/// 尘歌壶显示细胞
struct HouseCell: Identifiable {
    var id: String
    var name: String
    var visit_num: Int
    var level: Int
    var comfort_level_icon: String
    var comfort_level_name: String
    var icon: String
    var comfort_num: Int
    var item_num: Int
}

struct RegionDetail: Identifiable {
    var id: Int
    var offerings: [Offerings] // 除「七天神像」之外提供等级和奖励的地区可供奉交互
    var boss_list: [BossInfo] // 主要魔物
    var name: String // 地区名
    var area_exploration_list: [Areas] // 子区域的探索情况
    var exploration_percentage: Int // 整体区域探索度 (X ÷ 1000 x 100%)
    var level: Int // 地区声望等级
    var cover: String // 外部查看时的背景图
    var icon: String // 地区图
    var inner_icon: String // 详情页面的地区图
    var background_image: String // 详情页面的背景图
    var type: String // 世界类型
    var parent: Int // 父地区ID
    var seven_statue_level: Int //七天神像供奉等级
}

struct BossInfo {
    var kill_num: Int
    var name: String
}

struct Offerings {
    var name: String
    var icon: String
    var level: Int
}

struct Areas: Identifiable {
    var id: String
    var name: String
    var exploration_percentage: Int
}
