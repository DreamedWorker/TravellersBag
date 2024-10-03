//
//  AvatarModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/2.
//

import Foundation
import SwiftyJSON

class AvatarModel: ObservableObject {
    static let shared = AvatarModel()
    let avatarRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "avatars")
    var avatarOverview: URL?
    var avatarDetail: URL?
    
    @Published var showUI: Bool = false
    @Published var avatarList: [AvatarIntro] = []
    var overview: JSON? = nil
    var detail: JSON? = nil
    
    private init() {}
    
    func initSomething() {
        avatarOverview = avatarRoot.appending(component: "avatar_index_\(GlobalUIModel.exported.defAccount!.genshinUID!).json")
        avatarDetail = avatarRoot.appending(components: "avatar_detail_\(GlobalUIModel.exported.defAccount!.genshinUID!).json")
        if !FileManager.default.fileExists(atPath: avatarRoot.toStringPath()) {
            try! FileManager.default.createDirectory(at: avatarRoot, withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: avatarOverview!.toStringPath(), contents: nil)
            FileManager.default.createFile(atPath: avatarDetail!.toStringPath(), contents: nil)
        } else {
            loadFile()
        }
    }
    
    /// 从服务器获取数据 如果是更新数据用，记得先关闭页面显示并清除overview和detail这两个对象
    func getOrRefresh() async {
        do {
            let user = GlobalUIModel.exported.defAccount!
            let list = try await AvatarService.defalult.fetchCharacterList(user: user)
            let detail = try await AvatarService.defalult.fetchCharacterDetail(user: user, list: list)
            FileHandler.shared.writeUtf8String(path: avatarOverview!.toStringPath(), context: list.rawString()!)
            FileHandler.shared.writeUtf8String(path: avatarDetail!.toStringPath(), context: detail.rawString()!)
            DispatchQueue.main.async { [self] in
                loadFile()
                if showUI {
                    GlobalUIModel.exported.makeAnAlert(type: 1, msg: "获取数据成功")
                } else {
                    GlobalUIModel.exported.makeAnAlert(type: 3, msg: "出现了未知问题，请稍后重试。")
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.showUI = false
                GlobalUIModel.exported.makeAnAlert(type: 3, msg: "获取数据时失败，\(error.localizedDescription)")
            }
        }
    }
    
    func getAvatarDetail(id: Int) -> JSON? {
        let found = detail!["list"].arrayValue.filter({ $0["base"]["id"].intValue == id }).first
        return found
    }
    
    private func loadFile() {
        overview = try? JSON(data: FileHandler.shared.readUtf8String(path: avatarOverview!.toStringPath()).data(using: .utf8)!)
        detail = try? JSON(data: FileHandler.shared.readUtf8String(path: avatarDetail!.toStringPath()).data(using: .utf8)!)
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
                name: HoyoResKit.default.getNameById(id: String(midWeaponData["id"].intValue)), level: midWeaponData["level"].intValue,
                rarity: midWeaponData["rarity"].intValue, icon: HoyoResKit.default.getGachaItemIcon(key: String(midWeaponData["id"].intValue))
            )
            avatarList.append(
                AvatarIntro(
                    id: i["id"].intValue, name: HoyoResKit.default.getNameById(id: String(i["id"].intValue)), level: i["level"].intValue,
                    element: i["element"].stringValue, fetter: i["fetter"].intValue, rarity: i["rarity"].intValue,
                    icon: HoyoResKit.default.getGachaItemIcon(key: String(i["id"].intValue)), sideIcon: i["side_icon"].stringValue, weapon: weapon)
            )
        }
    }
}
