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
    @Published var showMoreOption = false
    @Published var showHutaoOption = false
    @Published var hutaoRecord: JSON? = nil
    
    func initSomething(context: NSManagedObjectContext) {
        dataManager = context
        gachaList.removeAll()
        do {
            gachaList = try dataManager!.fetch(GachaItem.fetchRequest()).filter({ $0.uid == HomeController.shared.currentUser!.genshinUID! })
            if !gachaList.isEmpty { showContextUI = true }
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
                    if !self.gachaList.isEmpty {
                        self.showContextUI = true
                    } else {
                        HomeController.shared.showErrorDialog(msg: NSLocalizedString("gacha.error.cloud_empty", comment: ""))
                    }
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
    
    /// 从标准化文档中导入
    func getRecordFromUigf(fileContext: String) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        var uids: [String] = []
        do {
            let file = try JSON(data: fileContext.data(using: .utf8)!)
            if file["info"]["version"].stringValue.contains("v4.0") {
                if file.contains(where: { $0.0.contains("hk4e") }) {
                    let hk4es = file["hk4e"].arrayValue
                    for singlePlayerRecords in hk4es {
                        let uid = singlePlayerRecords["uid"].stringValue
                        uids.append(uid)
                        for j in singlePlayerRecords["list"].arrayValue {
                            let itemId = j["item_id"].stringValue
                            let nameGroup = getItemChineseName(itemId: itemId)
                            if nameGroup != "none" {
                                let neoItem = GachaItem(context: dataManager!)
                                neoItem.uid = uid
                                neoItem.id = j["id"].stringValue
                                neoItem.name = String(nameGroup.split(separator: "@")[0])
                                neoItem.time = df.date(from: j["time"].stringValue)!
                                neoItem.rankType = String(nameGroup.split(separator: "@")[1])
                                neoItem.itemType = String(nameGroup.split(separator: "@")[2])
                                neoItem.gachaType = j["gacha_type"].stringValue
                            }
                        }
                        try dataManager!.save()
                    }
                    gachaList.removeAll()
                    gachaList = try dataManager!.fetch(GachaItem.fetchRequest())
                        .filter({ $0.uid == HomeController.shared.currentUser!.genshinUID! })
                    if !gachaList.isEmpty {
                        showContextUI = true
                    } else {
                        HomeController.shared.showErrorDialog(
                            msg: String.localizedStringWithFormat(
                                NSLocalizedString("gacha.error.file_empty", comment: ""), HomeController.shared.currentUser!.genshinUID!)
                        )
                    }
                    HomeController.shared.showInfomationDialog(
                        msg: String.localizedStringWithFormat(
                            NSLocalizedString("gacha.init.from_file_ok", comment: ""), uids.description)
                    )
                }
            } else {
                HomeController.shared.showErrorDialog(msg: NSLocalizedString("gacha.error.no_hk4e", comment: ""))
            }
        } catch {
            print(error)
            HomeController.shared.showErrorDialog(
                msg: String.localizedStringWithFormat(
                    NSLocalizedString("gacha.init.get_data_error", comment: ""),
                    error.localizedDescription)
            )
        }
    }
    
    /// 用于切换默认账号后的状态切换
    func refreshState() {
        gachaList.removeAll()
        do {
            gachaList = try dataManager!.fetch(GachaItem.fetchRequest())
                .filter({ $0.uid == HomeController.shared.currentUser!.genshinUID! })
            if !gachaList.isEmpty {
                showContextUI = true
            } else {
                HomeController.shared.showErrorDialog(msg: NSLocalizedString("gacha.error.local_empty", comment: ""))
            }
        } catch {
            HomeController.shared.showErrorDialog(
                msg: String.localizedStringWithFormat(
                    NSLocalizedString("gacha.init.get_data_error", comment: ""),
                    error.localizedDescription)
            )
        }
    }
    
    func updateDataFromHk4e() async throws {
        await self.removeAllData()
        try await getRecordFromHk4e()
    }
    
    /// 获取祈愿数据并打开弹窗
    func fetchRecordInfoFromHutao() async {
        if GlobalHutao.shared.hasAccount() {
            if hutaoRecord == nil { // 用于减少网络请求量
                do {
                    let result = try await HutaoService.shared.gachaEntries()
                    DispatchQueue.main.async {
                        self.hutaoRecord = result.arrayValue
                            .filter({ $0["Uid"].stringValue == HomeController.shared.currentUser!.genshinUID! }).first
                        self.showHutaoOption = true
                    }
                } catch {
                    DispatchQueue.main.async {
                        HomeController.shared.showErrorDialog(
                            msg: String.localizedStringWithFormat(
                                NSLocalizedString("gacha.hutao.error_entry", comment: ""),
                                error.localizedDescription)
                        )
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.showHutaoOption = true
                }
            }
        } else {
            do {
                try await HutaoService.shared.loginWithKeychain(dm: dataManager!)
                let result = try await HutaoService.shared.gachaEntries()
                DispatchQueue.main.async {
                    self.hutaoRecord = result.arrayValue
                        .filter({ $0["Uid"].stringValue == HomeController.shared.currentUser!.genshinUID! }).first
                    self.showHutaoOption = true
                }
            } catch {
                DispatchQueue.main.async {
                    HomeController.shared.showErrorDialog(msg: NSLocalizedString("hutaokit.no_account", comment: ""))
                }
            }
        }
    }
    
    /// 上传本地祈愿数据
    func uploadLocal2Hutao() async {
        let needFullUpload = hutaoRecord == nil
        do {
            let result = try await HutaoService.shared.uploadGachaRecord(
                records: gachaList, uid: HomeController.shared.currentUser!.genshinUID!, fullUpload: needFullUpload)
            if result["retcode"].intValue == 0 {
                DispatchQueue.main.async {
                    self.showHutaoOption = false
                    HomeController.shared.showInfomationDialog(msg: result["message"].string ?? "")
                }
            } else {
                DispatchQueue.main.async {
                    self.showHutaoOption = false
                    HomeController.shared.showErrorDialog(msg: String.localizedStringWithFormat(NSLocalizedString("gacha.hutao.record_upload_err", comment: ""), result["message"].string ?? "未知原因")
                    )
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.showHutaoOption = false
                HomeController.shared.showErrorDialog(msg: String.localizedStringWithFormat(NSLocalizedString("gacha.hutao.record_upload_err", comment: ""), error.localizedDescription)
                )
            }
        }
    }
    
    /// 删除胡桃的祈愿数据
    func removeRecord(uid: String) async {
        do {
            let result = try await HutaoService.shared.deleteGachaRecord(uid: uid)
            DispatchQueue.main.async {
                if result["retcode"].intValue == 0 {
                    self.showHutaoOption = false
                    self.hutaoRecord = nil
                    HomeController.shared.showInfomationDialog(msg: NSLocalizedString("gacha.hutao.record_delete_ok", comment: ""))
                } else {
                    self.showHutaoOption = false
                    HomeController.shared.showErrorDialog(
                        msg: String.localizedStringWithFormat(
                            NSLocalizedString("gacha.hutao.record_delete_no", comment: ""),
                            result["message"].string ?? "未知原因")
                    )
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.showHutaoOption = false
                HomeController.shared.showErrorDialog(
                    msg: String.localizedStringWithFormat(
                        NSLocalizedString("gacha.hutao.record_delete_no", comment: ""),
                        error.localizedDescription)
                )
            }
        }
    }
    
    /// 获取物品的名字和星级 不在库中返回none
    private func getItemChineseName(itemId: String) -> String {
        if itemId != "10008" {
            if itemId.count == 5 { // 武器
                if let target = HomeController.shared.weaponList.filter({ $0["Id"].intValue == Int(itemId)! }).first {
                    return "\(target["Name"].stringValue)@\(target["RankLevel"].intValue)@武器"
                } else {
                    return "none"
                }
            } else if itemId.count == 8 { // 角色
                if let target = HomeController.shared.avatarList.filter({ $0["Id"].intValue == Int(itemId)! }).first {
                    return "\(target["Name"].stringValue)@\(target["Quality"].intValue)@角色"
                } else {
                    return "none"
                }
            } else {
                return "none"
            }
        } else {
            return "none"
        }
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
        gachaList = try dataManager!.fetch(GachaItem.fetchRequest()).filter({ $0.uid == HomeController.shared.currentUser!.genshinUID! })
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
