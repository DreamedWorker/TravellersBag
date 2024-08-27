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
    
    private var allList: [JSON] = []
    private var errorPart: [String] = []
    
    private init(){
        if !FileManager.default.fileExists(atPath: fileDir.path().removingPercentEncoding!) {
            try! FileManager.default.createDirectory(
                atPath: fileDir.path().removingPercentEncoding!,
                withIntermediateDirectories: true
            )
        }
    }
    
    @Published var showContextUI = false
    @Published var gachaList: [GachaItem] = []
    
    func initSomething(context: NSManagedObjectContext) {
        dataManager = context
        gachaList.removeAll()
        do {
            gachaList = try dataManager!.fetch(GachaItem.fetchRequest())
            if !gachaList.isEmpty { showContextUI = true }
            print(gachaList.count)
        } catch {
            HomeController.shared.showErrorDialog(
                msg: String.localizedStringWithFormat(
                    NSLocalizedString("gacha.init.get_data_error", comment: ""),
                    error.localizedDescription)
            )
        }
    }
    
    /// 从官方渠道获取祈愿记录
    func getRecordFromHk4e() async throws {
        let user = HomeController.shared.currentUser! // 这里可以放心使用非空符号
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
                do {
                    try self.collectRecordsToCoreData(list: self.allList)
                    HomeController.shared.showLoadingDialog = false
                    self.showContextUI = true
                } catch {
                    DispatchQueue.main.async {
                        HomeController.shared.showLoadingDialog = false
                        HomeController.shared.showErrorDialog(
                            msg: String.localizedStringWithFormat(
                                NSLocalizedString("gacha.error.format_data", comment: ""), error.localizedDescription)
                        )
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                HomeController.shared.showLoadingDialog = false
                HomeController.shared.showErrorDialog(
                    msg: String.localizedStringWithFormat(
                        NSLocalizedString("gacha.error.fetch_info_err", comment: ""), self.errorPart.description)
                )
            }
        }
    }
    
    func updateDataFromHk4e() async throws {
        await self.removeAllData()
        try await getRecordFromHk4e()
    }
    
    /// 获取指定卡池的数据
    private func getSpecificRecord(key: String, type: String, end: String = "0") async throws -> [JSON] {
        var tempAllData: [JSON] = []
        func localFetchFunc(key: String, type: String, end: String = "0") async throws {
            var recordList = try await GachaService.shared.getGachaInfo(gachaType: type, authKey: key, endID: end)
            if recordList.count == 20 {
                for i in recordList {
                    tempAllData.append(i)
                }
                try await Task.sleep(for: .seconds(1.5)) // 中途延时 防止报错操作过快 模拟人的查看列表耗时
                let theLast = recordList.last!["id"].stringValue
                recordList.removeAll()
                try await localFetchFunc(key: key, type: type, end: theLast)
            } else {
                for i in recordList {
                    tempAllData.append(i)
                }
            }
        }
        try await localFetchFunc(key: key, type: type)
        return tempAllData
    }
    
    private func collectRecordsToCoreData(list: [JSON]) throws {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        for i in list {
            let neoItem = GachaItem(context: dataManager!)
            neoItem.gachaType = i["gacha_type"].stringValue
            neoItem.itemType = i["item_type"].stringValue
            neoItem.rankType = i["rank_type"].stringValue
            neoItem.time = df.date(from: i["time"].stringValue)!
            neoItem.uid = i["uid"].stringValue
            neoItem.id = i["id"].stringValue
            neoItem.name = i["name"].stringValue
            //neoItem.uuid = UUID().uuidString.lowercased()
        }
        let _ = CoreDataHelper.shared.save()
        gachaList.removeAll()
        gachaList = try dataManager!.fetch(GachaItem.fetchRequest())
    }
    
    func removeAllData() async {
        DispatchQueue.main.async {
            let current = self.gachaList
            for i in current {
                self.dataManager!.delete(i)
            }
            let _ = CoreDataHelper.shared.save()
            try! FileManager.default.removeItem(atPath: self.fileDir.path().removingPercentEncoding!)
            try! FileManager.default.createDirectory(
                atPath: self.fileDir.path().removingPercentEncoding!,
                withIntermediateDirectories: true
            )
        }
    }
}
