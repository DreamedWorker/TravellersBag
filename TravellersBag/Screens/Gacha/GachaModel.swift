//
//  GachaModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/23.
//

import Foundation
import CoreData
import SwiftyJSON

class GachaModel: ObservableObject {
    static let `default` = GachaModel()
    let gachaRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "gacha")
    private init() {
        if !FileManager.default.fileExists(atPath: gachaRoot.toStringPath()) {
            try! FileManager.default.createDirectory(at: gachaRoot, withIntermediateDirectories: true)
        }
    }
    private var dm: NSManagedObjectContext?
    let beginnerGacha = "100" //初行者推荐
    let residentGacha = "200" //常驻
    let characterGacha = "301" //角色
    let weaponGacha = "302" //武器
    let collectionGacha = "500" //混池
    
    // MARK: INNER USE start
    var errorPart: [String] = []
    var allList: [JSON] = []
    // MARK: INNER USE end
    
    @Published var uiPart: GachaViewPart = .NoData
    @Published var gachaPart: GachaPart = .Overview
    @Published var gachaList: [GachaItem] = []
    
    /// 初始化一些变量
    func initSomething(dm: NSManagedObjectContext) {
        self.dm = dm
        if let temp = try? dm.fetch(GachaItem.fetchRequest()) {
            gachaList.append(contentsOf: temp)
            if !gachaList.isEmpty { uiPart = .Showing }
        }
    }
    
    /// 从官方源更新数据
    func updateDataFromCloud() async {
        let user = GlobalUIModel.exported.defAccount!
        do {
            let authKeyB = try await GachaService.shared.getAuthKeyB(user: user) //这是验证KeyB
            do { // 初行者推荐池
                let beginnerRecord = try await GachaService.shared.getGachaInfo(gachaType: beginnerGacha, authKey: authKeyB)
                allList.append(contentsOf: beginnerRecord)
                do { // 角色活动池 301 400 两个池
                    let characterRecord = try await GachaService.shared.getGachaInfo(gachaType: characterGacha, authKey: authKeyB)
                    allList.append(contentsOf: characterRecord)
                    do { // 武器池
                        let weaponRecord = try await GachaService.shared.getGachaInfo(gachaType: weaponGacha, authKey: authKeyB)
                        allList.append(contentsOf: weaponRecord)
                        do { // 混池 集录祈愿池
                            let collectionRecord = try await GachaService.shared.getGachaInfo(gachaType: collectionGacha, authKey: authKeyB)
                            allList.append(contentsOf: collectionRecord)
                            do { // 常驻池
                                let residentRecord = try await GachaService.shared.getGachaInfo(gachaType: residentGacha, authKey: authKeyB)
                                allList.append(contentsOf: residentRecord)
                            } catch { errorPart.append(residentGacha) }
                        } catch { errorPart.append(collectionGacha) }
                    } catch { errorPart.append(weaponGacha) }
                } catch { errorPart.append(characterGacha) }
            } catch { errorPart.append(beginnerGacha) }
            if errorPart.count == 0 || errorPart.count < 5 {
                DispatchQueue.main.async { [self] in
                    GlobalUIModel.exported.showLoading.showIt = false
                    GlobalUIModel.exported.makeAnAlert(
                        type: 1,
                        msg: String.localizedStringWithFormat(
                            NSLocalizedString("gacha.info.update_from_cloud", comment: ""),
                            String(self.processHk4e2CoreData(hk4eList: allList, uid: user.genshinUID!)))
                    )
                    uiPart = .Showing
                }
            } else {
                DispatchQueue.main.async { [self] in
                    GlobalUIModel.exported.showLoading.showIt = false
                    GlobalUIModel.exported.makeAnAlert(type: 3, msg: String.localizedStringWithFormat(
                        NSLocalizedString("gacha.error.fetch_info_err", comment: ""), errorPart.description))
                }
            }
        } catch {
            DispatchQueue.main.async {
                GlobalUIModel.exported.showLoading.showIt = false
                GlobalUIModel.exported.makeAnAlert(type: 3, msg: String.localizedStringWithFormat(
                    NSLocalizedString("gacha.error.get_authkey", comment: ""), error.localizedDescription))
            }
        }
    }
    
    /// 从UIGF文件更新数据
    func updateDataFromFile(url: URL) {
        let thisUserID = GlobalUIModel.exported.defAccount!.genshinUID!
        do {
            let fileContent = try GachaService.shared.updateGachaInfoFromFile(fileContext: String(contentsOf: url, encoding: .utf8), uid: thisUserID)
            if fileContent.isEmpty || fileContent.count == 0 {
                GlobalUIModel.exported.makeAnAlert(
                    type: 3, msg: String.localizedStringWithFormat(NSLocalizedString("gacha.error.file_empty", comment: ""), thisUserID))
            } else {
                GlobalUIModel.exported.makeAnAlert(
                    type: 1,
                    msg: String.localizedStringWithFormat(
                        NSLocalizedString("gacha.info.update_from_file", comment: ""),
                        String(processUigf2CoreData(uigfList: fileContent, uid: thisUserID)))
                )
                uiPart = .Showing
            }
        } catch {
            GlobalUIModel.exported.makeAnAlert(
                type: 3,
                msg: String.localizedStringWithFormat(NSLocalizedString("gacha.error.import_from_file", comment: ""), error.localizedDescription)
            )
        }
    }
    
    /// 删除本地全部祈愿数据
    func deleteRecordsFromCoreData() {
        let transfer = gachaList
        transfer.forEach { one in
            CoreDataHelper.shared.deleteOne(single: one)
        }
        _ = CoreDataHelper.shared.save()
    }
    
    /// 将Hk4e的json转换到CoreData并存储
    private func processHk4e2CoreData(hk4eList: [JSON], uid: String) -> Int {
        var count = 0
        for one in hk4eList {
            if one["item_id"].stringValue == "10008" { continue }
            if !gachaList.isEmpty {
                if gachaList.contains(where: { $0.id! == one["id"].stringValue }) { continue }
            } // 自动增量更新配置
            if one["uid"].stringValue != uid { continue } //不知道是否会触发
            let neoItem = GachaItem(context: dm!)
            neoItem.gachaType = one["gacha_type"].stringValue
            neoItem.itemType = one["item_type"].stringValue
            neoItem.rankType = one["rank_type"].stringValue
            neoItem.time = transferTimeToDate(data: one["time"].stringValue)
            neoItem.uid = one["uid"].stringValue
            neoItem.id = one["id"].stringValue
            neoItem.name = one["name"].stringValue
            count += 1
        }
        _ = CoreDataHelper.shared.save()
        gachaList.removeAll()
        gachaList = fetchLocalData()
        allList.removeAll()
        return count
    }
    
    /// 将UIGF的json转换到CoreData并存储
    private func processUigf2CoreData(uigfList: [JSON], uid: String) -> Int {
        var count = 0
        for one in uigfList {
            if one["item_id"].stringValue == "10008" { continue } // 不在列表中的直接跳过 不执行后面的
            if !gachaList.isEmpty {
                if gachaList.contains(where: { $0.id! == one["id"].stringValue }) { continue }
            } // 自动增量更新配置
            let nameAndRank = GachaService.shared.getItemChineseName(itemId: one["item_id"].stringValue).split(separator: "@")
            if String(nameAndRank[2]) == "?" { continue }
            let neoItem = GachaItem(context: dm!)
            neoItem.uid = uid
            neoItem.id = one["id"].stringValue
            neoItem.name = String(nameAndRank[0])
            neoItem.time = transferTimeToDate(data: one["time"].stringValue)
            neoItem.rankType = String(nameAndRank[1])
            neoItem.itemType = String(nameAndRank[2])
            neoItem.gachaType = one["gacha_type"].stringValue
            count += 1
        }
        _ = CoreDataHelper.shared.save()
        gachaList.removeAll()
        gachaList = fetchLocalData()
        return count
    }
    
    /// 从CoreData中提取祈愿数据
    private func fetchLocalData() -> [GachaItem] {
        do {
            return try dm!.fetch(GachaItem.fetchRequest()).filter({ $0.uid == GlobalUIModel.exported.defAccount!.genshinUID! })
        } catch {
            uiPart = .LoadedError
            return []
        }
    }
    
    private func transferTimeToDate(data: String) -> Date {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df.date(from: data)!
    }
    
    /// 祈愿总页面部分
    enum GachaViewPart {
        /// 没有数据（或者错误）
        case NoData
        /// 显示内容
        case Showing
        /// 加载错误
        case LoadedError
    }
    
    enum GachaPart {
        case Overview
        case Activity
    }
}
