//
//  EnkaAvatar.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/17.
//

import Foundation

/// 从Enka处获取到的角色总数据
struct EnkaAvatar: Identifiable, Hashable, Equatable {
    static func == (lhs: EnkaAvatar, rhs: EnkaAvatar) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(avatarId)
    }
    
    var id: ObjectIdentifier?
    /// 角色ID 可以做很多事情，比如提取角色头像、天赋图标
    let avatarId: String // 假设从官方获取数据，也是可以拿到这个值的，值跟Enka中的一致
    /// 角色等级
    let avatarLevel: String
    /// 好感等级
    let fetterInfo: String
    /// 战斗属性JSON 可直接提取数据
    let fightProp: JSON
    /// 装备的圣遗物（列表可以是空的，需要判断size）
    let artifacts: [EnkaArtifact]
    /// 装备的武器 也可能没有武器
    let weapon: EnkaWeapon?
    /// 天赋ID
    let skillDepotId: String
    /// 天赋等级图
    let skillLevelMap: JSON
    /// 激活的命座数量
    let skillCount: Int
    
    init(
        avatarId: String, avatarLevel: String, fetterInfo: String, fightProp: JSON, artifacts: [EnkaArtifact],
        weapon: EnkaWeapon?, skillDepotId: String, skillLevelMap: JSON, skillCount: Int
    ) {
        self.avatarId = avatarId
        self.avatarLevel = avatarLevel
        self.fetterInfo = fetterInfo
        self.fightProp = fightProp
        self.artifacts = artifacts
        self.weapon = weapon
        self.skillDepotId = skillDepotId
        self.skillLevelMap = skillLevelMap
        self.skillCount = skillCount
    }
}

/// 武器信息
struct EnkaWeapon {
    /// 等级
    var level: Int
    /// 名称 需要进行翻译
    var name: String
    /// 图标
    var icon: String
    /// 武器词条
    var states: [EnkaArtifactInfo]
    /// 精炼情况 需要在原数上加1
    var affix: Int
    /// 物品ID
    var itemId: Int
}

/// 圣遗物信息
struct EnkaArtifact { // type -> ITEM_RELIQUARY
    /// 等级 当前数-1就是等级，如果等于1则不减
    let level: Int
    /// 名称 需要进行翻译
    let name: String // setNameTextMapHash
    /// 图标
    let icon: String
    /// 主词条
    let mainStat: EnkaArtifactInfo
    /// 副词条
    let subStat: [EnkaArtifactInfo]
    /// 物品ID
    let itemId: Int
}

/// 圣遗物（武器）词条信息
struct EnkaArtifactInfo {
    /// 词条名 可以直接放到loc.json中去提取翻译
    let propID: String
    /// 词条的值 只要有小数点就加百分号
    let statValue: String
}
