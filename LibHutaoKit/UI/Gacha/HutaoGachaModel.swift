//
//  HutaoGachaModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/2.
//

import Foundation
import CoreData
import SwiftyJSON

class HutaoGachaModel: ObservableObject {
    var dm: NSManagedObjectContext? = nil
    var hutaoAccount: HutaoAccount? = nil
    let fs = FileManager.default
    let hutaoRecordRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "libHutao")
    
    var recordInfo: JSON? = nil
    var syncCount: Int = 0
    
    init() {
        if !fs.fileExists(atPath: hutaoRecordRoot.toStringPath()) {
            try! fs.createDirectory(at: hutaoRecordRoot, withIntermediateDirectories: true)
        }
    }
    
    @Published var showUI: Bool = false
    @Published var gachaCloudRecord: [HutaoRecordEntry] = []
    
    func initSomething(dm: NSManagedObjectContext) {
        self.dm = dm
        hutaoAccount = try? dm.fetch(HutaoAccount.fetchRequest()).first
        if hutaoAccount != nil {
            showUI = true
            fetchRecordInfo()
        }
    }
    
    /// 加载（刷新）本地的云祈愿记录缓存
    func fetchRecordInfo(isRefresh: Bool = false) {
        func getDataFromNetwork() {
            fs.createFile(atPath: recordFile.toStringPath(), contents: nil)
            Task {
                do {
                    let context = try await HutaoService.default.gachaEntries(hutao: hutaoAccount!)
                    FileHandler.shared.writeUtf8String(path: recordFile.toStringPath(), context: context.rawString()!)
                    DispatchQueue.main.async { [self] in
                        recordInfo = context
                        for i in context.arrayValue {
                            gachaCloudRecord.append(
                                HutaoRecordEntry(id: i["Uid"].stringValue, Excluded: i["Excluded"].boolValue, ItemCount: i["ItemCount"].intValue)
                            )
                        }
                        gachaCloudRecord = gachaCloudRecord.filter({ $0.id == GlobalUIModel.exported.defAccount!.genshinUID! })
                    }
                } catch {
                    DispatchQueue.main.async {
                        GlobalUIModel.exported.makeAnAlert(
                            type: 3,
                            msg: String.localizedStringWithFormat(
                                NSLocalizedString("hutao.error.fetch_gacha_info", comment: ""), error.localizedDescription)
                        )
                    }
                }
            }
        }
        
        recordInfo = nil
        gachaCloudRecord.removeAll()
        let recordFile = hutaoRecordRoot.appending(component: "record_info.json")
        if !isRefresh {
            if !fs.fileExists(atPath: recordFile.toStringPath()) {
                fs.createFile(atPath: recordFile.toStringPath(), contents: nil)
                getDataFromNetwork()
            } else {
                let context = FileHandler.shared.readUtf8String(path: recordFile.toStringPath())
                if context != "" || !context.isEmpty {
                    do {
                        recordInfo = try JSON(data: context.data(using: .utf8)!)
                        for i in recordInfo!.arrayValue {
                            gachaCloudRecord.append(
                                HutaoRecordEntry(id: i["Uid"].stringValue, Excluded: i["Excluded"].boolValue, ItemCount: i["ItemCount"].intValue)
                            )
                        }
                        gachaCloudRecord = gachaCloudRecord.filter({ $0.id == GlobalUIModel.exported.defAccount!.genshinUID! })
                    } catch {
                        getDataFromNetwork()
                    }
                }
            }
        } else {
            getDataFromNetwork()
        }
    }
    
    func uploadGachaRecord(isFullUpload: Bool = false) async {
        let uid = GlobalUIModel.exported.defAccount!.genshinUID!
        do {
            let processedData = try await processDataWithRequire(
                records: getLocalRecord(), uid: uid,
                hutao: hutaoAccount!, fullUpload: isFullUpload
            )
            let result = try await HutaoService.default.uploadGachaRecord(records: processedData, uid: uid, hutao: hutaoAccount!)
            DispatchQueue.main.async {
                GlobalUIModel.exported.makeAnAlert(type: 1, msg: result["message"].string ?? "完成上传任务")
                self.fetchRecordInfo(isRefresh: true)
            }
        } catch {
            DispatchQueue.main.async {
                GlobalUIModel.exported.makeAnAlert(type: 3, msg: "上传失败，\(error.localizedDescription)")
            }
        }
    }
    
    func deleteCloudRecord() async {
        do {
            let result = try await HutaoService.default.deleteGachaRecord(
                uid: GlobalUIModel.exported.defAccount!.genshinUID!, hutao: hutaoAccount!
            )
            DispatchQueue.main.async {
                self.fetchRecordInfo(isRefresh: true)
                GlobalUIModel.exported.makeAnAlert(type: 1, msg: result["message"].string ?? "删除操作执行成功")
            }
        } catch {
            DispatchQueue.main.async {
                GlobalUIModel.exported.makeAnAlert(type: 3, msg: "删除失败，\(error.localizedDescription)")
            }
        }
    }
    
    func updateRecordFromHutao() async {
        syncCount = 0
        var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.gachaRetrieve())!)
        req.setHost(host: "homa.snapgenshin.com")
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(hutaoAccount!.auth!)", forHTTPHeaderField: "Authorization")
        do {
            let endids = try await HutaoService.default.fetchRecordEndIDs(uid: GlobalUIModel.exported.defAccount!.genshinUID!, hutao: hutaoAccount!)
            let result = try await req.receiveOrThrowHutao(isPost: true, reqBody: """
{
"Uid": "\(GlobalUIModel.exported.defAccount!.genshinUID!)", 
"EndIds": {
"100": \(endids["data"]["100"].intValue), 
"200": \(endids["data"]["200"].intValue), 
"301": \(endids["data"]["301"].intValue),
"302": \(endids["data"]["302"].intValue),
"500": \(endids["data"]["500"].intValue)
}
}
""".data(using: .utf8))
            let localRecord = try getLocalRecord()
            DispatchQueue.main.async { [self] in
                for i in result["data"].arrayValue {
                    if localRecord.contains(where: { $0.id! == String(i["Id"].intValue) }) {
                        continue
                    } else {
                        let neoItem = GachaItem(context: dm!)
                        let info = HoyoResKit.default.getGachaItemIcon(key: String(i["ItemId"].intValue))
                        neoItem.gachaType = String(i["GachaType"].intValue)
                        neoItem.id = String(i["Id"].intValue)
                        neoItem.itemType = (String(i["ItemId"].intValue).count == 5) ? "武器" : "角色"
                        neoItem.name = HoyoResKit.default.getNameById(id: String(i["ItemId"].intValue))
                        neoItem.rankType = String(info.split(separator: "@")[3])
                        neoItem.time = num2date(req: i["Time"].stringValue)
                        neoItem.uid = GlobalUIModel.exported.defAccount!.genshinUID!
                        syncCount += 1
                    }
                }
                _ = CoreDataHelper.shared.save()
                GlobalUIModel.exported.makeAnAlert(
                    type: 1,
                    msg: String.localizedStringWithFormat(NSLocalizedString("hutao.gacha.sync_ok", comment: ""), String(syncCount))
                )
            }
        } catch {
            DispatchQueue.main.async {
                GlobalUIModel.exported.makeAnAlert(
                    type: 3,
                    msg: String.localizedStringWithFormat(NSLocalizedString("hutao.gacha.error_sync", comment: ""), error.localizedDescription)
                )
            }
        }
    }
    
    private func processDataWithRequire(
        records: [GachaItem],
        uid: String,
        hutao: HutaoAccount,
        fullUpload: Bool
    ) async throws -> Data {
        var temp: [HutaoGachaItem] = []
        func dealList(list: [GachaItem]){
            for i in list {
                let nameId = HoyoResKit.default.getIdByName(name: i.name!)
                if nameId != "0" {
                    temp.append(HutaoGachaItem(GachaType: Int(i.gachaType!)!, QueryType: Int((i.gachaType! == "400") ? "301" : i.gachaType!)!, ItemId: Int(nameId)!, Time: timeTransfer(d: i.time!), Id: Int(i.id!)!))
                } else { continue } // 找不到ID的物品不上传
            }
        }
        let beginner = records.filter({ $0.gachaType == "100"}).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        let character = records.filter({ $0.gachaType == "301" || $0.gachaType == "400" }).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        let weapon = records.filter({ $0.gachaType == "302" }).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        let resident = records.filter({ $0.gachaType == "200" }).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        let collection = records.filter({ $0.gachaType == "500" }).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        if fullUpload {
            dealList(list: records)
        } else {
            let endids = try await HutaoService.default.fetchRecordEndIDs(uid: uid, hutao: hutao)
            if !beginner.isEmpty {
                if endids["data"]["100"].intValue <= Int(beginner.last!.id!)! {
                    dealList(list: beginner.filter({ Int($0.id!)! > endids["data"]["100"].intValue }))
                }
            }
            if !character.isEmpty {
                if endids["data"]["301"].intValue <= Int(character.last!.id!)! {
                    dealList(list: character.filter({ Int($0.id!)! > endids["data"]["301"].intValue }))
                }
            }
            if !weapon.isEmpty {
                if endids["data"]["302"].intValue <= Int(weapon.last!.id!)! {
                    dealList(list: weapon.filter({ Int($0.id!)! > endids["data"]["302"].intValue }))
                }
            }
            if !resident.isEmpty {
                if endids["data"]["200"].intValue <= Int(resident.last!.id!)! {
                    dealList(list: resident.filter({ Int($0.id!)! > endids["data"]["200"].intValue }))
                }
            }
            if !collection.isEmpty {
                if endids["data"]["500"].intValue <= Int(collection.last!.id!)! {
                    dealList(list: collection.filter({ Int($0.id!)! > endids["data"]["500"].intValue }))
                }
            }
        }
        let summary = HutaoGachaUpload(Uid: uid, Items: temp)
        return try JSONEncoder().encode(summary)
    }
    
    private func timeTransfer(d: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'+00:00'"
        return df.string(from: d)
    }
    
    private func num2date(req: String) -> Date {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'+00:00'"
        return df.date(from: req)!
    }
    
    private func getLocalRecord() throws -> [GachaItem] {
        let mid = try? dm!.fetch(GachaItem.fetchRequest())
        if let surely = mid {
            if surely.count > 0 {
                return surely
            } else { return [] }
        } else {
            throw NSError(
                domain: "icu.bluedream.travellersbag.hutao", code: 1,
                userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("hutao.gacha.error_load_local", comment: "")]
            )
        }
    }
}
