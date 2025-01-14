//
//  HutaoLoginViewModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/11.
//

import Foundation
import SwiftyJSON
import SwiftData

extension HutaoLogin {
    
    class HutaoLoginViewModel: ObservableObject, @unchecked Sendable {
        var passport: HutaoPassport?
        let fs = FileManager.default
        let hutaoRecordRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(component: "HutaoPassport")
        var recordInfo: JSON? = nil
        
        @Published var gachaCloudRecord: [HutaoRecordEntry] = []
        @Published var alertMate = AlertMate()
        @Published var email = ""
        @Published var pasword = ""
        
        init() {
            if !fs.fileExists(atPath: hutaoRecordRoot.toStringPath()) {
                try! fs.createDirectory(at: hutaoRecordRoot, withIntermediateDirectories: true)
            }
        }
        
        func initIt(hutao: HutaoPassport) {
            passport = hutao
        }
        
        func dismissBefore() {
            email = ""; pasword = ""
        }
        
        /// 加载本地文件中的云祈愿记录信息
        @MainActor func fetchRecordInfo(miAccount: MihoyoAccount?, useNetwork: Bool = false) async {
            recordInfo = nil
            gachaCloudRecord.removeAll()
            let recordFile = hutaoRecordRoot.appending(component: "RecordInfo.json")
            
            func getFromNetwork() async {
                if !fs.fileExists(atPath: recordFile.toStringPath()) {
                    fs.createFile(atPath: recordFile.toStringPath(), contents: nil)
                }
                do {
                    let context = try await JSON(data: TBHutaoService.gachaEntries(hutao: passport!))
                    try! context.rawString()!.write(to: recordFile, atomically: true, encoding: .utf8)
                    recordInfo = context
                    for i in context.arrayValue {
                        gachaCloudRecord.append(
                            HutaoRecordEntry(id: i["Uid"].stringValue, Excluded: i["Excluded"].boolValue, ItemCount: i["ItemCount"].intValue)
                        )
                    }
                    gachaCloudRecord = gachaCloudRecord.filter({ $0.id == miAccount?.gameInfo.genshinUID ?? "" })
                } catch {
                    alertMate.showAlert(msg: String.localizedStringWithFormat(
                        NSLocalizedString("hutao.error.fetch_gacha_info", comment: ""), error.localizedDescription)
                    )
                }
            }
            
            if !useNetwork {
                if !fs.fileExists(atPath: recordFile.toStringPath()) {
                    await getFromNetwork()
                } else {
                    let context = try! String(contentsOf: recordFile, encoding: .utf8)
                    if context != "" || !context.isEmpty {
                        do {
                            recordInfo = try JSON(data: context.data(using: .utf8)!)
                            for i in recordInfo!.arrayValue {
                                gachaCloudRecord.append(
                                    HutaoRecordEntry(id: i["Uid"].stringValue, Excluded: i["Excluded"].boolValue, ItemCount: i["ItemCount"].intValue)
                                )
                            }
                            gachaCloudRecord = gachaCloudRecord.filter({ $0.id == miAccount?.gameInfo.genshinUID ?? "" })
                        } catch {
                            await getFromNetwork()
                        }
                    } else {
                        await getFromNetwork()
                    }
                }
            } else {
                await getFromNetwork()
            }
        }
        
        @MainActor func tryLogin() async -> HutaoPassport? {
            do {
                let result = try await JSON(data: TBHutaoService.loginPassport(username: email, passwordOri: pasword))
                let userInfo = try await JSON(data: TBHutaoService.userInfo(auth: result["data"].stringValue))
                let neoAccount = HutaoPassport(
                    auth: result["data"].stringValue, gachaLogExpireAt: userInfo["GachaLogExpireAt"].stringValue,
                    isLicensedDeveloper: userInfo["IsLicensedDeveloper"].boolValue, isMaintainer: userInfo["IsMaintainer"].boolValue,
                    normalizedUserName: userInfo["NormalizedUserName"].stringValue, userName: userInfo["UserName"].stringValue)
                DispatchQueue.main.async { [self] in
                    email = ""; pasword = ""
                }
                return neoAccount
            } catch {
                print(error)
                alertMate.showAlert(
                    msg: String.localizedStringWithFormat(
                        NSLocalizedString("hutao.error.login", comment: ""),
                        error.localizedDescription)
                )
                return nil
            }
        }
        
        @MainActor func deleteCloudRecord(hoyoAccount: MihoyoAccount) async {
            do {
                let result = try await JSON(data: TBHutaoService.deleteGachaRecord(
                    uid: hoyoAccount.gameInfo.genshinUID, hutao: passport!
                ))
                await fetchRecordInfo(miAccount: hoyoAccount, useNetwork: true)
                alertMate.showAlert(msg: result["message"].string ?? NSLocalizedString("hutao.info.recordDeleted", comment: ""))
            } catch {
                alertMate.showAlert(
                    msg: String.localizedStringWithFormat(
                        NSLocalizedString("hutao.error.deleteRecord", comment: ""),
                        error.localizedDescription)
                )
            }
        }
        
        @MainActor func updateRecord(user: MihoyoAccount, hutaoAccount: HutaoPassport, mc: ModelContext) async {
            var syncCount = 0
            let uid = user.gameInfo.genshinUID
            var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.gachaRetrieve())!)
            req.setHost(host: "homa.snapgenshin.com")
            req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(hutaoAccount.auth)", forHTTPHeaderField: "Authorization")
            do {
                let endids = try await JSON(data: TBHutaoService.fetchRecordEndIDs(uid: uid, hutao: hutaoAccount.auth))
                let result = try await JSON(data: req.receiveOrThrowHutao(isPost: true, reqBody: """
{
"Uid": "\(uid)", 
"EndIds": {
"100": \(endids["data"]["100"].intValue), 
"200": \(endids["data"]["200"].intValue), 
"301": \(endids["data"]["301"].intValue),
"302": \(endids["data"]["302"].intValue),
"500": \(endids["data"]["500"].intValue)
}
}
""".data(using: .utf8)))
                let localRecord = try getLocalRecord(uid: uid, mc: mc)
                DispatchQueue.main.async { [self] in
                    for i in result["data"].arrayValue {
                        if localRecord.contains(where: { $0.id == String(i["Id"].intValue) }) {
                            continue
                        } else {
                            let neoItem = GachaItem(
                                uid: uid,
                                id: String(i["Id"].intValue),
                                name: ResHandler.default.getGachaItemName(key: String(i["ItemId"].intValue)),
                                time: i["Time"].stringValue,
                                rankType: ResHandler.default.getItemRank(key: String(i["ItemId"].intValue)),
                                itemType: (String(i["ItemId"].intValue).count == 5) ? "武器" : "角色",
                                gachaType: String(i["GachaType"].intValue)
                            )
                            mc.insert(neoItem)
                            syncCount += 1
                        }
                    }
                    try! mc.save()
                    alertMate.showAlert(
                        msg: String.localizedStringWithFormat(
                            NSLocalizedString("hutao.info.syncOK", comment: ""),
                            String(syncCount), uid)
                    )
                }
            } catch {
                DispatchQueue.main.async { [self] in
                    alertMate.showAlert(
                        msg: String.localizedStringWithFormat(
                            NSLocalizedString("hutao.error.sync", comment: ""),
                            error.localizedDescription)
                    )
                }
            }
        }
        
        @MainActor func uploadGachaRecord(user: MihoyoAccount, mc: ModelContext, ht: HutaoPassport, isFullUpload: Bool = false) async {
            let uid = user.gameInfo.genshinUID
            do {
                let processedData = try await processDataWithRequire(
                    records: getLocalRecord(uid: uid, mc: mc), uid: uid,
                    hutao: ht.auth, fullUpload: isFullUpload
                )
                let result = try await JSON(data: TBHutaoService.uploadGachaRecord(records: processedData, uid: uid, hutao: ht.auth))
                await fetchRecordInfo(miAccount: user)
                DispatchQueue.main.async {
                    self.alertMate.showAlert(msg: result["message"].string ?? NSLocalizedString("hutao.info.uploadOK", comment: ""))
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertMate.showAlert(
                        msg: String.localizedStringWithFormat(
                            NSLocalizedString("hutao.error.upload", comment: ""),
                            error.localizedDescription)
                    )
                }
            }
        }
        
        private func getLocalRecord(uid: String, mc: ModelContext) throws -> [GachaItem] {
            let fetcher = FetchDescriptor<GachaItem>(predicate: #Predicate{ $0.uid == uid })
            return try mc.fetch(fetcher)
        }
        
        @MainActor private func processDataWithRequire(
            records: [GachaItem],
            uid: String,
            hutao: String,
            fullUpload: Bool
        ) async throws -> Data {
            var temp: [HutaoGachaItem] = []
            func dealList(list: [GachaItem]){
                for i in list {
                    let nameId = ResHandler.default.getIdByName(name: i.name)
                    if nameId != "0" {
                        temp.append(HutaoGachaItem(GachaType: Int(i.gachaType)!, QueryType: Int((i.gachaType == "400") ? "301" : i.gachaType)!, ItemId: Int(nameId)!, Time: timeTransfer(d: num2date(req: i.time)), Id: Int(i.id)!))
                    } else { continue } // 找不到ID的物品不上传
                }
            }
            let beginner = records.filter({ $0.gachaType == "100"}).sorted(by: { Int($0.id)! < Int($1.id)! })
            let character = records.filter({ $0.gachaType == "301" || $0.gachaType == "400" }).sorted(by: { Int($0.id)! < Int($1.id)! })
            let weapon = records.filter({ $0.gachaType == "302" }).sorted(by: { Int($0.id)! < Int($1.id)! })
            let resident = records.filter({ $0.gachaType == "200" }).sorted(by: { Int($0.id)! < Int($1.id)! })
            let collection = records.filter({ $0.gachaType == "500" }).sorted(by: { Int($0.id)! < Int($1.id)! })
            if fullUpload {
                dealList(list: records)
            } else {
                let endids = try await JSON(data: TBHutaoService.fetchRecordEndIDs(uid: uid, hutao: hutao))
                if !beginner.isEmpty {
                    if endids["data"]["100"].intValue <= Int(beginner.last!.id)! {
                        dealList(list: beginner.filter({ Int($0.id)! > endids["data"]["100"].intValue }))
                    }
                }
                if !character.isEmpty {
                    if endids["data"]["301"].intValue <= Int(character.last!.id)! {
                        dealList(list: character.filter({ Int($0.id)! > endids["data"]["301"].intValue }))
                    }
                }
                if !weapon.isEmpty {
                    if endids["data"]["302"].intValue <= Int(weapon.last!.id)! {
                        dealList(list: weapon.filter({ Int($0.id)! > endids["data"]["302"].intValue }))
                    }
                }
                if !resident.isEmpty {
                    if endids["data"]["200"].intValue <= Int(resident.last!.id)! {
                        dealList(list: resident.filter({ Int($0.id)! > endids["data"]["200"].intValue }))
                    }
                }
                if !collection.isEmpty {
                    if endids["data"]["500"].intValue <= Int(collection.last!.id)! {
                        dealList(list: collection.filter({ Int($0.id)! > endids["data"]["500"].intValue }))
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
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return df.date(from: req)!
        }
    }
}
