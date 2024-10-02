//
//  HoyoResKit.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/15.
//

import Foundation
import SwiftyJSON

class HoyoResKit {
    static let `default` = HoyoResKit()
    let fs = FileManager.default
    let staticRoot = try! FileManager.default
        .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "globalStatic")
    
    var avatars: [JSON]
    var weapon: [JSON]
    var langs: [String: Int]
    private init() {
        if !fs.fileExists(atPath: staticRoot.toStringPath()) {
            try! fs.createDirectory(at: staticRoot, withIntermediateDirectories: true)
            try! String(contentsOf: Bundle.main.url(forResource: "Avatar", withExtension: "json")!).write(to: staticRoot.appending(component: "Avatar.json"), atomically: true, encoding: .utf8)
            try! String(contentsOf: Bundle.main.url(forResource: "Weapon", withExtension: "json")!).write(to: staticRoot.appending(component: "Weapon.json"), atomically: true, encoding: .utf8)
            try! String(contentsOf: Bundle.main.url(forResource: "zh-cn", withExtension: "json")!).write(to: staticRoot.appending(component: "zh-cn.json"), atomically: true, encoding: .utf8)
        }
        do {
            avatars = (UserDefaultHelper.shared.getValue(forKey: "dataSource", def: "") == "local-cloud") ?
            try JSON(data: String(contentsOf: staticRoot.appending(component: "cloud").appending(component: "Avatar.json"), encoding: .utf8).data(using: .utf8)!).arrayValue :
            try! JSON(data: String(contentsOf: staticRoot.appending(component: "Avatar.json"), encoding: .utf8).data(using: .utf8)!).arrayValue
        } catch {
            avatars = try! JSON(
                data: String(contentsOf: staticRoot.appending(component: "Avatar.json"), encoding: .utf8).data(using: .utf8)!).arrayValue
        }
        do {
            weapon = (UserDefaultHelper.shared.getValue(forKey: "dataSource", def: "") == "local-cloud") ?
            try JSON(data: String(contentsOf: staticRoot.appending(component: "cloud").appending(component: "Weapon.json"), encoding: .utf8).data(using: .utf8)!).arrayValue :
            try! JSON(data: String(contentsOf: staticRoot.appending(component: "Weapon.json"), encoding: .utf8).data(using: .utf8)!).arrayValue
        } catch {
            weapon = try! JSON(
                data: String(contentsOf: staticRoot.appending(component: "Weapon.json"), encoding: .utf8).data(using: .utf8)!).arrayValue
        }
        langs = try! JSONSerialization.jsonObject(with: String(contentsOf: staticRoot.appending(component: "zh-cn.json"), encoding: .utf8).data(using: .utf8)!) as! [String: Int]
    }
    
    /// 获取游戏角色头像 可能是链接也可能是本地文件路径
    /// 格式：类型@地址
    func getCharacterHeadAddress(key: String) -> String {
        let pfps = try! JSON(data: String(contentsOf: Bundle.main.url(forResource: "pfps", withExtension: "json")!).data(using: .utf8)!)
        if pfps.contains(where: { $0.0 == key }) {
            let primaryName = pfps[key]["iconPath"].stringValue
            let localStorePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appending(component: "globalStatic").appending(component: "images").appending(components: "AvatarIconCircle")
            if FileManager.default.fileExists(atPath: localStorePath.toStringPath()) {
                let files = try! FileManager.default.contentsOfDirectory(atPath: localStorePath.toStringPath())
                if files.contains("\(primaryName).png") {
                    return "L@\(localStorePath.appending(component: "\(primaryName).png").toStringPath())"
                } else {
                    return "C@https://enka.network/ui/\(primaryName).png"
                }
            } else {
                return "C@https://enka.network/ui/\(primaryName).png"
            }
        } else {
            return "C@about:blank"
        }
    }
    
    /// 根据图片的分类和文件名获取地址
    func getImageWithNameAndType(type: String, name: String) -> String {
        let localStorePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(component: "globalStatic").appending(component: "images").appending(components: type).appending(component: "\(name).png")
        if fs.fileExists(atPath: localStorePath.toStringPath()) {
            return "L@\(localStorePath.toStringPath())"
        } else {
            return "C@https://enka.network/ui/\(name).png"
        }
    }
    
    /// 获取抽卡物品的图像和名称（其实也可以不要）
    /// 格式：类型@地址@名称@星级
    func getGachaItemIcon(key: String) -> String {
        var result = ""
        if key.count == 5 {
            if weapon.count > 0 {
                if weapon.contains(where: { $0["Id"].intValue == Int(key) }) {
                    let entry = weapon.filter({ $0["Id"].intValue == Int(key) }).first!
                    let imgKey = entry["Icon"].stringValue
                    let localPath = staticRoot.appending(component: "images").appending(component: "EquipIcon").appending(components: "\(imgKey).png")
                    if fs.fileExists(atPath: localPath.toStringPath()) {
                        result = "L@\(localPath.toStringPath())@\(entry["Name"].stringValue)@\(entry["RankLevel"].intValue)"
                    } else {
                        result = "C@https://enka.network/ui/\(imgKey).png@\(entry["Name"].stringValue)@\(entry["RankLevel"].intValue)"
                    }
                } else {
                    result = "C@about:blank@???@0"
                }
            } else {
                result = "C@about:blank@???@0"
            }
        } else if key.count == 8 {
            if avatars.count > 0 {
                if avatars.contains(where: { $0["Id"].intValue == Int(key) }) {
                    let entry = avatars.filter({ $0["Id"].intValue == Int(key) }).first!
                    let imgKey = entry["Icon"].stringValue
                    let localPath = staticRoot.appending(component: "images").appending(component: "AvatarIcon").appending(component: "\(imgKey).png")
                    if fs.fileExists(atPath: localPath.toStringPath()) {
                        result = "L@\(localPath.toStringPath())@\(entry["Name"].stringValue)@\(entry["Quality"].intValue)"
                    } else {
                        result = "C@https://enka.network/ui/\(imgKey).png@\(entry["Name"].stringValue)@\(entry["Quality"].intValue)"
                    }
                } else {
                    result = "C@about:blank@???@0"
                }
            } else {
                result = "C@about:blank@???@0"
            }
        } else {
            result = "C@about:blank@???@0"
        }
        return result
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
    
    /// 通过ID获取名称 找不到的话返回「?」
    func getNameById(id: String) -> String {
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
}
