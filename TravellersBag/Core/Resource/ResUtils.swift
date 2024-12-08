//
//  ResUtils.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/12/6.
//

import Foundation
import SwiftyJSON

extension ResHandler {
    /// 根据图片的分类和文件名获取地址
    func getImageWithNameAndType(type: String, name: String) -> TBResource {
        let b = ResHandler.default.useLocalStorage(type: .Images, folderOrFile: "\(type)/\(name)")
        return TBResource(
            useLocal: b,
            resPath: b ?
            self.staticRoot.appending(component: type).appending(component: name).toStringPath() :
                "https://enka.network/ui/\(name).png"
        )
    }
}

extension ResHandler {
    /// 通过ID获取名称 找不到的话返回「?」
    func getGachaItemName(key id: String) -> String {
        if id == "10000007" { return NSLocalizedString("traveller.name", comment: "") }
        if id.count == 5 {
            if weapon.contains(where: { $0["Id"].intValue == Int(id) }) {
                let result = weapon.filter({ $0["Id"].intValue == Int(id) }).first!
                return result["Name"].stringValue
            } else { return "?" }
        } else if id.count == 8 {
            if avatars.contains(where: { $0["Id"].intValue == Int(id) }) {
                let result = avatars.filter({ $0["Id"].intValue == Int(id) }).first!
                return result["Name"].stringValue
            } else { return "?" }
        } else { return "?" }
    }
    
    /// 通过名称获取ID
    func getIdByName(name: String) -> String {
        if avatars.contains(where: { $0["Name"].stringValue == name }) {
            let result = avatars.filter({ $0["Name"].stringValue == name }).first!
            return String(result["Id"].intValue)
        } else if weapon.contains(where: { $0["Name"].stringValue == name }) {
            let result = weapon.filter({ $0["Name"].stringValue == name }).first!
            return String(result["Id"].intValue)
        } else {
            return "0"
        }
    }
    
    /// 获取角色或武器星级
    func getItemRank(key id: String) -> String {
        if id.count == 5 {
            let entry = weapon.filter({ $0["Id"].intValue == Int(id) }).first!
            return "\(entry["RankLevel"].intValue)"
        } else if id.count == 8 {
            let entry = avatars.filter({ $0["Id"].intValue == Int(id) }).first!
            return "\(entry["Quality"].intValue)"
        } else {
            return "0"
        }
    }
}

extension ResHandler {
    /// 通过ID获取圣遗物的图标 找不到的话返回空 这就会导致加载云端图片而不是本地的
    func getReliquaryIcon(id: String) -> TBResource {
        let searched = reliquary.filter({ ($0["Ids"].arrayObject as! [Int]).contains(Int(id)!) }).first
        if let surely = searched {
            return getImageWithNameAndType(type: "RelicIcon", name: surely["Icon"].stringValue)
        } else {
                return TBResource(useLocal: false, resPath: "about:blank")
        }
    }
    
    func getGachaItemIcon(key: String) -> TBResource {
        if key.count == 5 {
            if weapon.count > 0 {
                if weapon.contains(where: { $0["Id"].intValue == Int(key) }) {
                    let entry = weapon.filter({ $0["Id"].intValue == Int(key) }).first!
                    let imgKey = entry["Icon"].stringValue
                    let localPath = resRoot.appending(component: "EquipIcon").appending(components: "\(imgKey).png")
                    if FileManager.default.fileExists(atPath: localPath.toStringPath()) {
                        return TBResource(useLocal: true, resPath: localPath.toStringPath())
                    } else {
                        return TBResource(useLocal: false, resPath: "https://enka.network/ui/\(imgKey).png")
                    }
                } else {
                    return TBResource(useLocal: false, resPath: "about:blank")
                }
            } else {
                return TBResource(useLocal: false, resPath: "about:blank")
            }
        } else if key.count == 8 {
            if avatars.count > 0 {
                if avatars.contains(where: { $0["Id"].intValue == Int(key) }) {
                    let entry = avatars.filter({ $0["Id"].intValue == Int(key) }).first!
                    let imgKey = entry["Icon"].stringValue
                    let localPath = resRoot.appending(component: "AvatarIcon").appending(component: "\(imgKey).png")
                    if FileManager.default.fileExists(atPath: localPath.toStringPath()) {
                        return TBResource(useLocal: true, resPath: localPath.toStringPath())
                    } else {
                        return TBResource(useLocal: false, resPath: "https://enka.network/ui/\(imgKey).png")
                    }
                } else {
                    return TBResource(useLocal: false, resPath: "about:blank")
                }
            } else {
                return TBResource(useLocal: false, resPath: "about:blank")
            }
        } else {
            return TBResource(useLocal: false, resPath: "about:blank")
        }
    }
}
