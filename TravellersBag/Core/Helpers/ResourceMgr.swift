//
//  ResourceMgr.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/3/8.
//

import AppKit
import Foundation
import SwiftyJSON

final class ResourceMgr {
    static let shared = ResourceMgr()
    
    private let resRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(path: "resource").appending(path: "imgs")
    
    private var avatars: [JSON]
    private var weapon: [JSON]
    private var reliquary: [JSON]
    private var gachaEvent: [JSON]
    private var profilePics: [JSON]
    
    private init() {
        avatars = readAndPrase(resourceName: "Avatar")
        weapon = readAndPrase(resourceName: "Weapon")
        reliquary = readAndPrase(resourceName: "Reliquary")
        gachaEvent = readAndPrase(resourceName: "GachaEvent")
        profilePics = readAndPrase(resourceName: "ProfilePicture")
    }
}

extension ResourceMgr {
    /// 获取指定文件夹（分类）下的图片
    func getDisplayImage(part: String, name: String) -> NSImage? {
        let requiredImg = resRoot.appending(component: part).appending(component: "\(name).png")
        if FileManager.default.fileExists(atPath: requiredImg.toStringPath()) {
            return NSImage(contentsOf: requiredImg)
        } else {
            return nil
        }
    }
    
    /// 获取特定 ID 所代表的头像
    func getProfilePicture(picID: String) -> NSImage? {
        if profilePics.contains(where: { $0["id"].intValue == Int(picID) }) {
            let result = profilePics.filter({ $0["id"].intValue == Int(picID) }).first!
            return getDisplayImage(part: "AvatarIconCircle", name: result["Icon"].stringValue)
        } else {
            return nil
        }
    }
}

func readAndPrase(resourceName: String) -> [JSON] {
    func readFromBuiltIn() -> [JSON] {
        return try! JSON(data: Data(contentsOf: Bundle.main.url(forResource: resourceName, withExtension: "json")!)).arrayValue
    }
    
    let staticRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(path: "resource").appending(path: "jsons")
    let requiredFile = staticRoot.appending(component: "\(resourceName).json")
    if FileManager.default.fileExists(atPath: requiredFile.toStringPath()) {
        if let got = try? JSON(data: Data(contentsOf: requiredFile)).arrayValue {
            return got
        } else {
            return readFromBuiltIn()
        }
    } else {
        return readFromBuiltIn()
    }
}
