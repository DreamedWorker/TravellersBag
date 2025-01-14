//
//  AvatarViewModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/14.
//

import Foundation
@preconcurrency import SwiftyJSON

extension AvatarView {
    
    class AvatarViewModel: ObservableObject, @unchecked Sendable {
        let avatarRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(component: "Avatars")
        
        @Published var showUI: Bool = false
        @Published var avatarList: [AvatarIntro] = []
        @Published var alertMate = AlertMate()
        
        var overview: JSON? = nil
        var detail: JSON? = nil
        
        init() {
            if !FileManager.default.fileExists(atPath: avatarRoot.toStringPath()) {
                try! FileManager.default.createDirectory(at: avatarRoot, withIntermediateDirectories: true)
            }
        }
        
        func hasAccountData(uid: String) -> Bool {
            let entrance = avatarRoot.appending(component: uid)
            if !FileManager.default.fileExists(atPath: entrance.toStringPath()) {
                try! FileManager.default.createDirectory(at: entrance, withIntermediateDirectories: true)
            }
            if let _ = try? FileManager.default.contentsOfDirectory(atPath: avatarRoot.toStringPath()).filter({ $0 == uid }).first {
                if FileManager.default.fileExists(atPath: entrance.appending(component: "AvatarIndex.json").toStringPath())
                    && FileManager.default.fileExists(atPath: entrance.appending(component: "AvatarDetail.json").toStringPath()) {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }
        
        /// 从服务器获取数据 如果是更新数据用，记得先关闭页面显示并清除overview和detail这两个对象
        @MainActor func getOrRefresh(user: MihoyoAccount, useNetwork:Bool = false) async {
            let entrance = avatarRoot.appending(component: user.gameInfo.genshinUID)
            if !FileManager.default.fileExists(atPath: entrance.toStringPath()) {
                try! FileManager.default.createDirectory(at: entrance, withIntermediateDirectories: true)
            }
            func getFromNetwork() async {
                do {
                    let list = try await AvatarService.defalult.fetchCharacterList(user: user)
                    let detail = try await AvatarService.defalult.fetchCharacterDetail(user: user, list: list)
                    try! list.rawString()!.write(to: entrance.appending(component: "AvatarIndex.json"), atomically: true, encoding: .utf8)
                    try! detail.rawString()!.write(to: entrance.appending(component: "AvatarDetail.json"), atomically: true, encoding: .utf8)
                    let uid = user.gameInfo.genshinUID
                    DispatchQueue.main.async { [self] in
                        loadFile(user: uid)
                        if showUI {
                            alertMate.showAlert(msg: NSLocalizedString("avatar.info.fetch_ok", comment: ""))
                        } else {
                            alertMate.showAlert(msg: NSLocalizedString("avatar.error.fetch_unknown", comment: ""))
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.showUI = false
                        self.alertMate.showAlert(msg: String.localizedStringWithFormat(NSLocalizedString("avatar.error.fetch", comment: ""), error.localizedDescription))
                    }
                }
            }
            func getFromLocal() async {
                if !FileManager.default.fileExists(atPath: entrance.toStringPath()) {
                    try! FileManager.default.createDirectory(at: entrance, withIntermediateDirectories: true)
                    FileManager.default.createFile(atPath: entrance.appending(component: "AvatarIndex.json").toStringPath(), contents: nil)
                    FileManager.default.createFile(atPath: entrance.appending(component: "AvatarDetail.json").toStringPath(), contents: nil)
                    await getFromNetwork()
                } else {
                    if let midList = try? JSON(data: Data(contentsOf: entrance.appending(component: "AvatarIndex.json"))),
                       let midDetail = try? JSON(data: Data(contentsOf: entrance.appending(component: "AvatarDetail.json"))) {
                        overview = midList; detail = midDetail
                        makeAvatarList()
                        showUI = true
                    } else {
                        await getFromNetwork()
                    }
                }
            }
            
            if useNetwork {
                await getFromNetwork()
            } else {
                await getFromLocal()
            }
        }
        
        func getAvatarDetail(id: Int) -> JSON? {
            let found = detail!["list"].arrayValue.filter({ $0["base"]["id"].intValue == id }).first
            return found
        }
        
        /// 根据ID返回参数名
        func getPropName(id: String) -> String {
            if detail!["property_map"].contains(where: { $0.0 == id }) {
                let mid = detail!["property_map"][id]
                return mid["name"].stringValue
            } else {
                return "???"
            }
        }
        
        private func loadFile(user: String) {
            let entrance = avatarRoot.appending(component: user)
            overview = try? JSON(data: Data(contentsOf: entrance.appending(component: "AvatarIndex.json")))
            detail = try? JSON(data: Data(contentsOf: entrance.appending(component: "AvatarDetail.json")))
            if overview != nil && detail != nil {
                makeAvatarList()
                showUI = true
            }
        }
        
        private func makeAvatarList() {
            avatarList.removeAll()
            for i in overview!["list"].arrayValue {
                let midWeaponData = i["weapon"]
                let weapon = AvatarEquipedWeapon(
                    affix_level: midWeaponData["affix_level"].intValue, id: midWeaponData["id"].intValue,
                    name: ResHandler.default.getGachaItemName(key: String(midWeaponData["id"].intValue)), level: midWeaponData["level"].intValue,
                    rarity: midWeaponData["rarity"].intValue,
                    icon: ResHandler.default.getGachaItemIcon(key: String(midWeaponData["id"].intValue)).resPath
                )
                if i["id"].intValue == 10000007 { // 解决「旅行者」的正面头像不能显示的问题
                    avatarList.append(
                        AvatarIntro(
                            id: i["id"].intValue,
                            name: ResHandler.default.getGachaItemName(key: String(i["id"].intValue)), level: i["level"].intValue,
                            element: i["element"].stringValue, fetter: i["fetter"].intValue, rarity: i["rarity"].intValue,
                            icon: "\(i["icon"].stringValue.replacingOccurrences(of: "\\", with: ""))", sideIcon: i["side_icon"].stringValue,
                            weapon: weapon
                        )
                    )
                } else {
                    avatarList.append(
                        AvatarIntro(
                            id: i["id"].intValue,
                            name: ResHandler.default.getGachaItemName(key: String(i["id"].intValue)), level: i["level"].intValue,
                            element: i["element"].stringValue, fetter: i["fetter"].intValue, rarity: i["rarity"].intValue,
                            icon: ResHandler.default.getGachaItemIcon(key: String(i["id"].intValue)).resPath,
                            sideIcon: i["side_icon"].stringValue,
                            weapon: weapon
                        )
                    )
                }
            }
        }
    }
}
