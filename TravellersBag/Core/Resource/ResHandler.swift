//
//  ResHandler.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/12/6.
//

import Foundation
import SwiftyJSON

class ResHandler: @unchecked Sendable {
    static let `default` = ResHandler()
    let resRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(path: "resource").appending(path: "imgs")
    let staticRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(path: "resource").appending(path: "jsons")
    
    var avatars: [JSON]
    var weapon: [JSON]
    var reliquary: [JSON]
    var gachaEvent: [JSON]
    
    init() {
        if UserDefaults.standard.bool(forKey: "useLocalTextResource") {
            if let got = try? JSON(data: Data(contentsOf: staticRoot.appending(component: "Avatar.json"))).arrayValue {
                avatars = got
            } else {
                avatars = try! JSON(data: Data(contentsOf: Bundle.main.url(forResource: "Avatar", withExtension: "json")!)).arrayValue
            }
        } else {
            avatars = try! JSON(data: Data(contentsOf: Bundle.main.url(forResource: "Avatar", withExtension: "json")!)).arrayValue
        }
        
        if UserDefaults.standard.bool(forKey: "useLocalTextResource") {
            if let got = try? JSON(data: Data(contentsOf: staticRoot.appending(component: "Weapon.json"))).arrayValue {
                weapon = got
            } else {
                weapon = try! JSON(data: Data(contentsOf: Bundle.main.url(forResource: "Weapon", withExtension: "json")!)).arrayValue
            }
        } else {
            weapon = try! JSON(data: Data(contentsOf: Bundle.main.url(forResource: "Weapon", withExtension: "json")!)).arrayValue
        }
        
        if UserDefaults.standard.bool(forKey: "useLocalTextResource") {
            if let got = try? JSON(data: Data(contentsOf: staticRoot.appending(component: "Reliquary.json"))).arrayValue {
                reliquary = got
            } else {
                reliquary = try! JSON(data: Data(contentsOf: Bundle.main.url(forResource: "Reliquary", withExtension: "json")!)).arrayValue
            }
        } else {
            reliquary = try! JSON(data: Data(contentsOf: Bundle.main.url(forResource: "Reliquary", withExtension: "json")!)).arrayValue
        }
        
        if UserDefaults.standard.bool(forKey: "useLocalTextResource") {
            if let got = try? JSON(data: Data(contentsOf: staticRoot.appending(component: "GachaEvent.json"))).arrayValue {
                gachaEvent = got
            } else {
                gachaEvent = try! JSON(data: Data(contentsOf: Bundle.main.url(forResource: "GachaEvent", withExtension: "json")!)).arrayValue
            }
        } else {
            gachaEvent = try! JSON(data: Data(contentsOf: Bundle.main.url(forResource: "GachaEvent", withExtension: "json")!)).arrayValue
        }
    }
    
    func useLocalStorage(type: ResourceType, folderOrFile required: String) -> Bool {
        switch type {
        case .Images:
            let pathGroup = required.split(separator: "/")
            let truelyPath = resRoot.appending(component: String(pathGroup[0])).appending(component: String(pathGroup[1]))
            return FileManager.default.fileExists(atPath: truelyPath.toStringPath())
        case .Jsons:
            return FileManager.default.fileExists(atPath: staticRoot.appending(component: required).toStringPath())
        }
    }
    
    enum ResourceType {
        case Images
        case Jsons
    }
}

extension ResHandler {
    /// 资源代号
    public struct TBResource {
        /// 是否使用本地资源
        var useLocal: Bool
        /// 资源路径 或者说要显示的内容
        var resPath: String
    }
}
