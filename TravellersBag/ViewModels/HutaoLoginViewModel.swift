//
//  HutaoLoginViewModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/11.
//

import Foundation
import SwiftyJSON

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
                alertMate.showAlert(msg: "无法登录你的通行证：\(error.localizedDescription)")
                return nil
            }
        }
        
        @MainActor func deleteCloudRecord(hoyoAccount: MihoyoAccount) async {
            do {
                let result = try await JSON(data: TBHutaoService.deleteGachaRecord(
                    uid: hoyoAccount.gameInfo.genshinUID, hutao: passport!
                ))
                await fetchRecordInfo(miAccount: hoyoAccount, useNetwork: true)
                alertMate.showAlert(msg: result["message"].string ?? "删除操作执行成功")
            } catch {
                alertMate.showAlert(msg: "删除失败，\(error.localizedDescription)")
            }
        }
    }
}
