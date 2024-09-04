//
//  GachaModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/23.
//

import Foundation
import CoreData

class GachaModel: ObservableObject {
    static let shared = GachaModel()
    let fileDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "gacha")
    var dataManager: NSManagedObjectContext? = nil
    let beginnerGacha = "100" //初行者推荐
    let residentGacha = "200" //常驻
    let characterGacha = "301" //角色
    let weaponGacha = "302" //武器
    let collectionGacha = "500" //混池
    
    private init(){
        if !FileManager.default.fileExists(atPath: fileDir.path().removingPercentEncoding!) {
            try! FileManager.default.createDirectory(
                atPath: fileDir.path().removingPercentEncoding!,
                withIntermediateDirectories: true
            )
        }
        hasUser = HomeController.shared.currentUser != nil
    }
    
    @Published var showContextUI = false
    @Published var gachaList: [GachaItem] = []
    @Published var showMoreOption = false
    @Published var showHutaoOption = false
    @Published var hutaoRecord: JSON? = nil
    @Published var hasUser = false
    
    func initSomething(context: NSManagedObjectContext) {
        dataManager = context
        gachaList.removeAll()
        gachaList = fetchLocalData()
    }
    
    /// 删除本地全部祈愿数据
    func deleteRecordsFromCoreData() {
        let transfer = gachaList
        transfer.forEach { one in
            CoreDataHelper.shared.deleteOne(single: one)
        }
        _ = CoreDataHelper.shared.save()
    }
    
    /// 从UIGF文件更新数据
    func updateFromUigf(url: URL) {
        let uid = HomeController.shared.currentUser!.genshinUID!
        do {
            if hasUser {
                let gachaList = try GachaService.shared.updateGachaInfoFromFile(
                    fileContext: String(contentsOf: url),
                    uid: uid)
                if gachaList.isEmpty {
                    HomeController.shared.showErrorDialog(
                        msg: String.localizedStringWithFormat(NSLocalizedString("gacha.error.file_empty", comment: ""), uid))
                } else {
                    HomeController.shared.showInfomationDialog(
                        msg: String.localizedStringWithFormat(
                            NSLocalizedString("gacha.init.from_file_ok", comment: ""),
                            String(processUigf2CoreData(uigfList: gachaList, uid: uid))))
                }
            }
        } catch {
            HomeController.shared.showErrorDialog(
                msg: String.localizedStringWithFormat(
                    NSLocalizedString("gacha.update.error_deal_uigf_file", comment: ""), error.localizedDescription))
        }
    }
    
    /// 从官方更新数据
    func updateFromHk4e() async {
        let user = HomeController.shared.currentUser!
        var allList: [JSON] = []
        var errorPart: [String] = []
        do {
            if hasUser {
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
                    DispatchQueue.main.async {
                        HomeController.shared.showLoadingDialog = false
                        HomeController.shared.showInfomationDialog(
                            msg: String.localizedStringWithFormat(
                                NSLocalizedString("gacha.update_info", comment: ""),
                                String(self.processHk4e2CoreData(hk4eList: allList, uid: user.genshinUID!))))
                    }
                } else {
                    DispatchQueue.main.async {
                        HomeController.shared.showLoadingDialog = false
                        HomeController.shared.showErrorDialog(
                            msg: String.localizedStringWithFormat(
                                NSLocalizedString("gacha.error.fetch_info_err", comment: ""), errorPart.description)
                        )
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                HomeController.shared.showLoadingDialog = false
                HomeController.shared.showErrorDialog(
                    msg: String.localizedStringWithFormat(
                        NSLocalizedString("gacha.error.get_authkey", comment: ""), error.localizedDescription))
            }
        }
    }
    
    /// 将UIGF的json转换到CoreData并存储
    private func processUigf2CoreData(uigfList: [JSON], uid: String) -> Int {
        var count = 0
        for one in uigfList {
            if one["item_id"].stringValue == "10008" { continue } // 不在列表中的直接跳过 不执行后面的
            if !gachaList.isEmpty {
                if gachaList.contains(where: { $0.id! == one["id"].stringValue }) { continue }
            } // 自动增量更新配置
            let nameAndRank = GachaService.shared.getItemChineseName(itemId: one["item_id"].stringValue)
            if nameAndRank == "none" { continue }
            let neoItem = GachaItem(context: dataManager!)
            neoItem.uid = uid
            neoItem.id = one["id"].stringValue
            neoItem.name = String(nameAndRank.split(separator: "@")[0])
            neoItem.time = transferTimeToDate(data: one["time"].stringValue)
            neoItem.rankType = String(nameAndRank.split(separator: "@")[1])
            neoItem.itemType = String(nameAndRank.split(separator: "@")[2])
            neoItem.gachaType = one["gacha_type"].stringValue
            count += 1
        }
        _ = CoreDataHelper.shared.save()
        gachaList.removeAll()
        gachaList = fetchLocalData()
        return count
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
            let neoItem = GachaItem(context: dataManager!)
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
        return count
    }
    
    /// 从CoreData中提取祈愿数据 如果没有登录则不提取任何数据
    private func fetchLocalData() -> [GachaItem] {
        if hasUser {
            do {
                return try dataManager!.fetch(GachaItem.fetchRequest()).filter({ $0.uid == HomeController.shared.currentUser!.genshinUID! })
            } catch {
                HomeController.shared.showErrorDialog(
                    msg: String.localizedStringWithFormat(
                        NSLocalizedString("gacha.init.get_data_error", comment: ""),
                        error.localizedDescription)
                )
                return []
            }
        } else {
            return []
        }
    }
    
    private func transferTimeToDate(data: String) -> Date {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df.date(from: data)!
    }
}
