//
//  CultivationData.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/21.
//

import Foundation
import SwiftData

struct SkillEntry: Codable, Identifiable {
    var id: Int
    var group_id: Int
    var name: String
    var icon: String
    var max_level: Int
    var level_current: Int
}

struct WeaponEntry: Codable, Identifiable {
    var id: Int
    var name: String
    var icon: String
    var weapon_cat_id: Int
    var weapon_level: Int
    var max_level: Int
    var level_current: Int
}

struct ReliquaryEntry: Codable, Identifiable {
    var id: Int
    var name: String
    var icon: String
    var reliquary_cat_id: Int
    var reliquary_level: Int
    var max_level: Int
    var level_current: Int
}



struct AvatarEntry: Codable, Identifiable {
    var id: Int
    var name: String
    var icon: String
    var weapon_cat_id: Int
    var avatar_level: Int
    var element_attr_id: Int
    var max_level: Int
    var level_current: Int
    var promote_level: Int
    var skill_list: [SkillEntry]
    var weapon: WeaponEntry
    var reliquary_list: [ReliquaryEntry]
}
