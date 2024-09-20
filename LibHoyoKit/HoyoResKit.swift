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
    
    var avatars: JSON
    var weapon: JSON
    var langs: [String: Int]
    private init() {
        if !fs.fileExists(atPath: staticRoot.toStringPath()) {
            try! fs.createDirectory(at: staticRoot, withIntermediateDirectories: true)
            try! String(contentsOf: Bundle.main.url(forResource: "Avatar", withExtension: "json")!).write(to: staticRoot.appending(component: "Avatar.json"), atomically: true, encoding: .utf8)
            try! String(contentsOf: Bundle.main.url(forResource: "Weapon", withExtension: "json")!).write(to: staticRoot.appending(component: "Weapon.json"), atomically: true, encoding: .utf8)
            try! String(contentsOf: Bundle.main.url(forResource: "zh-cn", withExtension: "json")!).write(to: staticRoot.appending(component: "zh-cn.json"), atomically: true, encoding: .utf8)
        }
        avatars = try! JSON(data: String(contentsOf: staticRoot.appending(component: "Avatar.json"), encoding: .utf8).data(using: .utf8)!)
        weapon = try! JSON(data: String(contentsOf: staticRoot.appending(component: "Weapon.json"), encoding: .utf8).data(using: .utf8)!)
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
}
