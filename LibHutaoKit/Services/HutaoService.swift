//
//  HutaoService.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/29.
//

import Foundation
import CryptoKit
import CoreData

class HutaoService {
    static let shared = HutaoService()
    private init() {}
    
    /// 访问胡桃云所需的公钥
    let publicKeyPEM = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5W2SEyZSlP2zBI1Sn8GdTwbZoXlUGNKyoVrY8SVYu9GMefdGZCrUQNkCG/Np8pWPmSSEFGd5oeug/oIMtCZQNOn0drlR+pul/XZ1KQhKmj/arWjN1XNok2qXF7uxhqD0JyNT/Fxy6QvzqIpBsM9S7ajm8/BOGlPG1SInDPaqTdTRTT30AuN+IhWEEFwT3Ctv1SmDupHs2Oan5qM7Y3uwb6K1rbnk5YokiV2FzHajGUymmSKXqtG1USZzwPqImpYb4Z0M/StPFWdsKqexBqMMmkXckI5O98GdlszEmQ0Ejv5Fx9fR2rXRwM76S4iZTfabYpiMbb4bM42mHMauupj69QIDAQAB"
    
    /// 返回加密的字符串
    private func encrypt(text: String) throws -> String {
        if let publicKey = publicKeyFromPEM(pemString: publicKeyPEM) {
            let plaintextData = text.data(using: .utf8)!
            var error: Unmanaged<CFError>?
            guard let encryptedData = SecKeyCreateEncryptedData(publicKey,.rsaEncryptionOAEPSHA1, plaintextData as CFData, &error) as Data? else {
                throw NSError(domain: "libhutaokit.crypto", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: String.localizedStringWithFormat(
                        NSLocalizedString("hutaokit.error.crypto", comment: ""), "\(error!.takeRetainedValue() as Error)")
                ])
            }
            return encryptedData.base64EncodedString()
        } else {
            throw NSError(domain: "libhutaokit.crypto", code: -2, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("hutaokit.error.crypto_key", comment: "")
            ])
        }
    }
    
    /// 登录通行证 传递明文即可
    func login(username: String, password: String) async throws -> JSON {
        let email = try encrypt(text: username)
        let password = try encrypt(text: password)
        var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.login())!)
        req.setHost(host: "homa.snapgenshin.com")
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let result = await req.receiveData(session: httpSession(), isPost: true, reqBody: try! JSONSerialization.data(withJSONObject: [
            "UserName": email, "Password": password
        ]))
        if result.evtState {
            let temp = try! JSON(data: (result.data as! String).data(using: .utf8)!)
            if temp["retcode"].intValue == 0 {
                return temp
            } else {
                throw NSError(domain: "libhutaokit", code: temp["retcode"].intValue, userInfo: [
                    NSLocalizedDescriptionKey: String.localizedStringWithFormat(NSLocalizedString("hutaokit.error.login", comment: ""), temp["message"].stringValue)
                ])
            }
        } else {
            throw NSError(domain: "libhutaokit.login", code: -1, userInfo: [
                NSLocalizedDescriptionKey: String.localizedStringWithFormat(
                    NSLocalizedString("hutaokit.error.login", comment: ""), result.data as! String
                )
            ])
        }
    }
    
    func loginWithKeychain(dm: NSManagedObjectContext) async throws {
        let account = try SecurityTool.shared.read(key: LocalEnvironment.shared.getEnvStringValue(key: LocalEnvironment.KEY_CHAIN_NAME))
        let result = try await login(username: account.username, password: account.password)
        DispatchQueue.main.async {
            let current = try! dm.fetch(HutaoAccount.fetchRequest()).filter({ $0.userName! == account.username }).first
            current?.auth = result["data"].stringValue
            let _ = CoreDataHelper.shared.save()
        }
    }
    
    /// 获取通行证信息
    func userInfo(auth: String) async throws -> JSON {
        var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.userInfo())!)
        req.setHost(host: "homa.snapgenshin.com")
        req.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")
        return try await req.receiveOrThrow()
    }
    
    /// 获取上传的抽卡记录信息
    func gachaEntries() async throws -> JSON {
        var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.gachaEntries())!)
        req.setHost(host: "homa.snapgenshin.com")
        req.setValue("Bearer \(GlobalHutao.shared.hutao!.auth!)", forHTTPHeaderField: "Authorization")
        return try await req.receiveOrThrow()
    }
    
    /// 删除云祈愿记录
    func deleteGachaRecord(uid: String) async throws -> JSON {
        var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.gachaDelete(uid: uid))!)
        req.setHost(host: "homa.snapgenshin.com")
        req.setValue("Bearer \(GlobalHutao.shared.hutao!.auth!)", forHTTPHeaderField: "Authorization")
        return try await req.receiveOrThrowHutao()
    }
    
    func fetchRecordEndIDs(uid: String) async throws -> JSON {
        var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.gachaEndIds(uid: uid))!)
        req.setHost(host: "homa.snapgenshin.com")
        req.setValue("Bearer \(GlobalHutao.shared.hutao!.auth!)", forHTTPHeaderField: "Authorization")
        return try await req.receiveOrThrowHutao()
    }
    
    /// 上传祈愿数据 由于胡桃云遵循增量上传规则，故需要进行本地与云端数据比对，但如果云端没有数据时则全量上传。
    func uploadGachaRecord(records: [GachaItem], uid: String, fullUpload: Bool) async throws -> JSON {
        let uploadData = await (fullUpload) ? try processData(records: records, uid: uid) : try processDataWithRequire(records: records, uid: uid)
        var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.gachaUpload())!)
        req.setHost(host: "homa.snapgenshin.com")
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(GlobalHutao.shared.hutao!.auth!)", forHTTPHeaderField: "Authorization")
        req.setValue("\(uploadData.count)", forHTTPHeaderField: "Content-Length")
        return try await req.receiveOrThrowHutao(isPost: true, reqBody: uploadData)
    }
    
    private func processDataWithRequire(records: [GachaItem], uid: String) async throws -> Data {
        var temp: [HutaoGachaItem] = []
        func dealList(list: [GachaItem]){
            for i in list {
                let name_id = (HomeController.shared.idTable.contains(where: { $0.0 == i.name! }))
                ? HomeController.shared.idTable[i.name!].intValue : 10008
                temp.append(
                    HutaoGachaItem(
                        GachaType: Int(i.gachaType!)!,
                        QueryType: Int((i.gachaType! == "400") ? "301" : i.gachaType!)!,
                        ItemId: name_id, Time: timeTransfer(d: i.time!), Id: Int(i.id!)!)
                )
            }
        }
        let beginner = records.filter({ $0.gachaType == "100"}).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        let character = records.filter({ $0.gachaType == "301" || $0.gachaType == "400" }).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        let weapon = records.filter({ $0.gachaType == "302" }).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        let resident = records.filter({ $0.gachaType == "200" }).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        let collection = records.filter({ $0.gachaType == "500" }).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        let endids = try await fetchRecordEndIDs(uid: uid)
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
        let summary = HutaoGachaUpload(Uid: uid, Items: temp)
        return try JSONEncoder().encode(summary)
    }
    
    private func processData(records: [GachaItem], uid: String) throws -> Data {
        var temp: [HutaoGachaItem] = []
        for i in records {
            let name_id = (HomeController.shared.idTable.contains(where: { $0.0 == i.name! }))
            ? HomeController.shared.idTable[i.name!].intValue : 10008
            temp.append(
                HutaoGachaItem(
                    GachaType: Int(i.gachaType!)!,
                    QueryType: Int((i.gachaType! == "400") ? "301" : i.gachaType!)!,
                    ItemId: name_id, Time: timeTransfer(d: i.time!), Id: Int(i.id!)!)
            )
        }
        let summary = HutaoGachaUpload(Uid: uid, Items: temp)
        return try JSONEncoder().encode(summary)
    }
    
    private func timeTransfer(d: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'+00:00'"
        return df.string(from: d)
    }
    
    private func publicKeyFromPEM(pemString: String) -> SecKey? {
        let base64String = pemString
        guard let publicKeyData = Data(base64Encoded: base64String) else {
            return nil
        }
        let publicKeyAttributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits: 2048
        ]
        var error: Unmanaged<CFError>?
        guard let publicKey = SecKeyCreateWithData(publicKeyData as CFData, publicKeyAttributes as CFDictionary, &error) else {
            return nil
        }
        return publicKey
    }
}
