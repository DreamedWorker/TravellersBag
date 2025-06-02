//
//  StaticHelper.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/6/1.
//

import AppKit
import Foundation
@preconcurrency import SwiftyJSON

class StaticHelper {
    static let avatars: [JSON]? = try? JSON(data: Data(contentsOf: StaticResource.getRequiredFile(name: "Avatar.json"))).arrayValue
    static let weapon: [JSON]? = try? JSON(data: Data(contentsOf: StaticResource.getRequiredFile(name: "Weapon.json"))).arrayValue
    static let reliquary: [JSON]? = try? JSON(data: Data(contentsOf: StaticResource.getRequiredFile(name: "Reliquary.json"))).arrayValue
    
    static func getIdByName(name: String) -> String {
        if (avatars?.contains(where: { $0["Name"].stringValue == name }) ?? false) {
            let result = avatars!.filter({ $0["Name"].stringValue == name }).first!
            return String(result["Id"].intValue)
        } else if (weapon?.contains(where: { $0["Name"].stringValue == name }) ?? false) {
            let result = weapon!.filter({ $0["Name"].stringValue == name }).first!
            return String(result["Id"].intValue)
        } else {
            return "0"
        }
    }
    
    static func getNameById(id: String) -> String {
        if id == "10000007" { return NSLocalizedString("traveller.name", comment: "") }
        if id.count == 5 {
            if (weapon?.contains(where: { $0["Id"].intValue == Int(id) }) ?? false) {
                let result = weapon!.filter({ $0["Id"].intValue == Int(id) }).first!
                return result["Name"].stringValue
            } else { return "?" }
        } else if id.count == 8 {
            if (avatars?.contains(where: { $0["Id"].intValue == Int(id) }) ?? false) {
                let result = avatars!.filter({ $0["Id"].intValue == Int(id) }).first!
                return result["Name"].stringValue
            } else { return "?" }
        } else { return "?" }
    }
    
    static func getItemRank(key id: String) -> String {
        if id.count == 5 {
            if (weapon?.contains(where: { $0["Id"].intValue == Int(id) }) ?? false) {
                let entry = weapon!.filter({ $0["Id"].intValue == Int(id) }).first!
                return "\(entry["RankLevel"].intValue)"
            } else {
                return "0"
            }
        } else if id.count == 8 {
            if (avatars?.contains(where: { $0["Id"].intValue == Int(id) }) ?? false) {
                let entry = avatars!.filter({ $0["Id"].intValue == Int(id) }).first!
                return "\(entry["Quality"].intValue)"
            } else {
                return "0"
            }
        } else {
            return "0"
        }
    }
    
    static func getIconById(id: String) -> NSImage {
        if id.count == 5 {
            if (weapon?.contains(where: { $0["Id"].intValue == Int(id) }) ?? false) {
                let entry = weapon!.filter({ $0["Id"].intValue == Int(id) }).first!
                let imgKey = "\(entry["Icon"].stringValue).png"
                guard let imgPath = PicResource.getRequiredImage(type: "EquipIcon", name: imgKey) else {
                    return NSImage(systemSymbolName: "questionmark.app.dashed", accessibilityDescription: nil)!
                }
                return NSImage(contentsOf: imgPath)!
            } else {
                return NSImage(systemSymbolName: "questionmark.app.dashed", accessibilityDescription: nil)!
            }
        } else if id.count == 8 {
            if (avatars?.contains(where: { $0["Id"].intValue == Int(id) }) ?? false) {
                let entry = avatars!.filter({ $0["Id"].intValue == Int(id) }).first!
                let imgKey = "\(entry["Icon"].stringValue).png"
                guard let imgPath = PicResource.getRequiredImage(type: "AvatarIcon", name: imgKey) else {
                    return NSImage(systemSymbolName: "questionmark.app.dashed", accessibilityDescription: nil)!
                }
                return NSImage(contentsOf: imgPath)!
            } else {
                return NSImage(systemSymbolName: "questionmark.app.dashed", accessibilityDescription: nil)!
            }
        } else {
            return NSImage(systemSymbolName: "questionmark.app.dashed", accessibilityDescription: nil)!
        }
    }
}
