//
//  CharacterModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/17.
//

import Foundation

/// UI状态 用于控制页面显示的内容
enum CharacterUIState {
    case Loading
    case Succeed
    case Failed
}

class CharacterModel: ObservableObject {
    static let shared = CharacterModel()
    var loc: JSON // 翻译信息 仅加载中文
    var characters: JSON // 角色详情
    
    private init() {
        let locFile = Bundle.main.url(forResource: "loc", withExtension: "json")!.path().removingPercentEncoding!
        let chaFile = Bundle.main.url(forResource: "characters", withExtension: "json")!.path().removingPercentEncoding!
        self.loc = try! JSON(data: FileHandler.shared.readUtf8String(path: locFile).data(using: .utf8)!)["zh-cn"]
        self.characters = try! JSON(data: FileHandler.shared.readUtf8String(path: chaFile).data(using: .utf8)!)
    }
    
    @Published var characterShowing: [EnkaAvatar] = [] // 要显示出去的角色信息
    @Published var characterDetail: EnkaAvatar? = nil
    @Published var uiState: CharacterUIState = .Loading
    @Published var showUpdateWindow = false
    
    /// 让界面显示内容 在初始化或者刷新内容时使用
    @MainActor func showCharacters(uid: String) {
        do {
            try tryGenerateCharacterFromEnka(uid: uid)
            uiState = .Succeed
        } catch {
            HomeController.shared.showErrorDialog(msg: "解析角色橱窗时出错：\(error.localizedDescription)")
            uiState = .Failed
        }
    }
    
    /// 向列表中追加来自Enka的角色信息
    @MainActor
    func tryGenerateCharacterFromEnka(uid: String) throws {
        let localFile = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(component: "characters_from_enka-\(uid).json").path().removingPercentEncoding!
        let fileContext = FileHandler.shared.readUtf8String(path: localFile)
        if !fileContext.isEmpty {
            let requiredJSON = try JSON(data: fileContext.data(using: .utf8)!)["avatarInfoList"].arrayValue
            for single in requiredJSON {
                let equipList = single["equipList"].arrayValue
                let artifacts = getEquipArtifactFromEnka(data: equipList)
                let weapon = getEquipWeaponFromEnka(data: equipList)
                let fightPropMap = single["fightPropMap"]
                let fetterInfo = String(single["fetterInfo"]["expLevel"].intValue)
                let avatarId = String(single["avatarId"].intValue)
                let level = single["propMap"]["4001"]["val"].stringValue
                let skillDepotId = String(single["skillDepotId"].intValue)
                let skillLevelMap = single["skillLevelMap"]
                var talentCounts = 0
                if single.contains(where: {$0.0 == "talentIdList"}){
                    talentCounts = single["talentIdList"].arrayObject!.count
                }
                if !characterShowing.contains(where: {$0.avatarId == avatarId}) {
                    characterShowing.append(
                        EnkaAvatar(
                            avatarId: avatarId, avatarLevel: level, fetterInfo: fetterInfo,
                            fightProp: fightPropMap, artifacts: artifacts, weapon: weapon,
                            skillDepotId: skillDepotId, skillLevelMap: skillLevelMap,
                            skillCount: talentCounts
                        ))
                } else {
                    let originOne = characterShowing.filter({$0.avatarId == avatarId}).first!
                    characterShowing.remove(at: characterShowing.firstIndex(of: originOne)!)
                    characterShowing.append(
                        EnkaAvatar(
                            avatarId: avatarId, avatarLevel: level, fetterInfo: fetterInfo,
                            fightProp: fightPropMap, artifacts: artifacts, weapon: weapon,
                            skillDepotId: skillDepotId, skillLevelMap: skillLevelMap,
                            skillCount: talentCounts
                        ))
                }
            }
        }
    }
    
    func updateCharactersFromEnka(uid: String) async {
        do {
            let newData = try await CharacterService.shared.pullCharactersFromEnka(
                gameUID: uid)
            let charactersFromEnka = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appending(component: "characters_from_enka-\(uid).json").path().removingPercentEncoding!
            if !FileManager.default.fileExists(atPath: charactersFromEnka) {
                FileManager.default.createFile(atPath: charactersFromEnka, contents: nil)
            } else {
                FileHandler.shared.writeUtf8String(path: charactersFromEnka, context: "")
            }
            FileHandler.shared.writeUtf8String(
                path: charactersFromEnka, context: String(data: newData, encoding: .utf8)!)
            try await self.tryGenerateCharacterFromEnka(uid: uid)
            DispatchQueue.main.async {
                self.uiState = .Succeed
                self.showUpdateWindow = false
                HomeController.shared.showInfomationDialog(
                    msg: NSLocalizedString("character.toast.refresh_successful", comment: ""))
            }
        } catch {
            DispatchQueue.main.async {
                self.uiState = .Failed
                self.showUpdateWindow = false
                HomeController.shared.showErrorDialog(
                    msg: String.localizedStringWithFormat(
                        NSLocalizedString("character.toast.refresh_failed", comment: ""),
                        error.localizedDescription
                    ))
            }
        }
    }
    
    /// 获取角色名的翻译后文本
    func getTranslationText(key: String) -> String {
        return loc[String(characters[key]["NameTextMapHash"].intValue)].stringValue
    }
    
    /// 获取角色头像
    func getCharacterIcon(key: String, isSide: Bool = true) -> String {
        var name = characters[key]["SideIconName"].stringValue
        if !isSide {
            name = name.replacingOccurrences(of: "Side_", with: "")
        }
        return getIconUrlFromEnka(name: name)
    }
    
    /// 返回包含角色天赋等级和图标链接的JSON数据
    func getCharacterSkillIconList(id: String, map: JSON) -> Data {
        let skillOrder = characters[id]["SkillOrder"].arrayObject!
        let a = String(skillOrder[0] as! Int) // 普通攻击（重击）id
        let s = String(skillOrder[1] as! Int) // 元素战技id
        let e = String(skillOrder[2] as! Int) // 元素爆发id
        let aLevel = String(map[a].intValue)
        let sLevel = String(map[s].intValue)
        let eLevel = String(map[e].intValue)
        let aIcon = getIconUrlFromEnka(name: characters[id]["Skills"][a].stringValue)
        let sIcon = getIconUrlFromEnka(name: characters[id]["Skills"][s].stringValue)
        let eIcon = getIconUrlFromEnka(name: characters[id]["Skills"][e].stringValue)
        return try! JSONSerialization.data(withJSONObject: [
            "al": aLevel, "sl": sLevel, "el": eLevel, "ai": aIcon, "si": sIcon, "ei": eIcon
        ])
    }
    
    /// 获取图标的链接
    func getIconUrlFromEnka(name: String) -> String {
        return "https://enka.network/ui/\(name).png"
    }
    
    private func getEquipArtifactFromEnka(data: [JSON]) -> [EnkaArtifact] {
        var artifacts: [EnkaArtifact] = []
        for single in data {
            let flat = single["flat"]
            if flat["itemType"] == "ITEM_RELIQUARY" {
                let icon = flat["icon"].stringValue // 圣遗物图标
                let name = flat["setNameTextMapHash"].stringValue // 名字的翻译key
                let reliquaryMainstat = flat["reliquaryMainstat"]
                let mainStat = EnkaArtifactInfo(
                    propID: reliquaryMainstat["mainPropId"].stringValue,
                    statValue: String(reliquaryMainstat["statValue"].intValue)) //主词条
                let reliquarySubstats = flat["reliquarySubstats"].arrayValue
                var subStat: [EnkaArtifactInfo] = [] // 副词条列表
                for substat in reliquarySubstats {
                    subStat.append(EnkaArtifactInfo(propID: substat["appendPropId"].stringValue, statValue: String(substat["statValue"].intValue)))
                }
                let itemId = single["itemId"].intValue
                let level = single["reliquary"]["level"].intValue
                artifacts.append(EnkaArtifact(level: level, name: name, icon: icon, mainStat: mainStat, subStat: subStat, itemId: itemId))
            }
        }
        return artifacts
    }
    
    private func getEquipWeaponFromEnka(data: [JSON]) -> EnkaWeapon {
        var tempWeapon = EnkaWeapon(level: 0, name: "", icon: "", states: [], affix: 0, itemId: 0)
        for single in data {
            let flat = single["flat"]
            if ["itemType"] == "ITEM_WEAPON" {
                let level = single["weapon"]["level"].intValue
                let icon = flat["icon"].stringValue
                let name = flat["nameTextMapHash"].stringValue
                var weaponStats: [EnkaArtifactInfo] = []
                for stat in flat["weaponStats"].arrayValue {
                    weaponStats.append(
                        EnkaArtifactInfo(
                            propID: stat["appendPropId"].stringValue,
                            statValue: String(stat["statValue"].intValue)
                        ))
                }
                let itemId = single["itemId"].intValue
                let affix = (single["weapon"]["1\(String(itemId))"].intValue) + 1
                tempWeapon.level = level
                tempWeapon.name = name
                tempWeapon.icon = icon
                tempWeapon.states = weaponStats
                tempWeapon.affix = affix
                tempWeapon.itemId = itemId
                break
            }
        }
        return tempWeapon
    }
}
