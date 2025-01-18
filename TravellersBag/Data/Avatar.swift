//
//  Avatar.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/3.
//

import Foundation

/// 角色装备的武器简介
struct AvatarEquipedWeapon: Hashable {
    /// 精炼等级
    var affix_level: Int
    /// ID
    var id: Int
    /// 名字
    var name: String
    var level: Int
    var rarity: Int
    var icon: String
}

/// 角色简介
struct AvatarIntro: Identifiable, Hashable {
    var id: Int
    var name: String
    var level: Int
    var element: String
    var fetter: Int
    var rarity: Int
    var icon: String
    var sideIcon: String
    var weapon: AvatarEquipedWeapon
}

/// 角色命座信息
struct Constellation: Identifiable {
    var id: Int
    var name: String
    var icon: String
    var localIcon: String?
    var is_actived: Bool
    var effect: String
}

/// 角色战斗天赋
struct AvatarSkill: Identifiable {
    var id: Int
    var level: Int
    var icon: String
    var localIcon: String?
    var skill_affix_list: [SkillAffixList]
    var skill_type: Int
    var name: String
    var desc: String
}

struct SkillAffixList {
    var name: String
    var value: String
}

/// 角色的属性
struct AvatarProperty: Identifiable {
    var id: Int
    var add: String
    var final: String
    var base: String
    var name: String
}

struct AvatarReliquary: Identifiable {
    var id: Int
    var rarity: Int
    var name: String
    var level: Int
    var icon: String
    var setName: String
    var mainProp: ReliquaryProp
    var subProps: [ReliquaryProp]
    var localIcon: String?
}

struct ReliquaryProp {
    var times: Int
    var value: String
    var property_type: Int
}
