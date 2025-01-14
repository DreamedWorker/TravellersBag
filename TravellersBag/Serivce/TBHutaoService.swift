//
//  TBHutaoService.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/5.
//

import Foundation
import SwiftyJSON

// 账号登录的部分
class TBHutaoService: @unchecked Sendable {
    private static let publicKeyPEM = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5W2SEyZSlP2zBI1Sn8GdTwbZoXlUGNKyoVrY8SVYu9GMefdGZCrUQNkCG/Np8pWPmSSEFGd5oeug/oIMtCZQNOn0drlR+pul/XZ1KQhKmj/arWjN1XNok2qXF7uxhqD0JyNT/Fxy6QvzqIpBsM9S7ajm8/BOGlPG1SInDPaqTdTRTT30AuN+IhWEEFwT3Ctv1SmDupHs2Oan5qM7Y3uwb6K1rbnk5YokiV2FzHajGUymmSKXqtG1USZzwPqImpYb4Z0M/StPFWdsKqexBqMMmkXckI5O98GdlszEmQ0Ejv5Fx9fR2rXRwM76S4iZTfabYpiMbb4bM42mHMauupj69QIDAQAB"
    private static func key2pem() throws -> SecKey {
        guard let keyData = Data(base64Encoded: publicKeyPEM) else { throw NSError() }
        let publicKeyAttributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits: 2048
        ]
        var error: Unmanaged<CFError>?
        guard let publicKey = SecKeyCreateWithData(keyData as CFData, publicKeyAttributes as CFDictionary, &error) else {
            throw NSError()
        }
        return publicKey
    }
    private static func encrypt(from text: String) throws -> String {
        let publicKey = try key2pem()
        let plaintextData = text.data(using: .utf8)!
        var error: Unmanaged<CFError>?
        guard let encryptedData = SecKeyCreateEncryptedData(publicKey,.rsaEncryptionOAEPSHA1, plaintextData as CFData, &error) as Data? else {
            throw NSError(domain: "libhutaokit.crypto", code: -1, userInfo: [
                NSLocalizedDescriptionKey: String.localizedStringWithFormat(
                    NSLocalizedString("hutao.error.crypto", comment: ""), "\(error!.takeRetainedValue() as Error)")
            ])
        }
        return encryptedData.base64EncodedString()
    }
    
    static func loginPassport(username: String, passwordOri: String, writeKeychain: Bool = true) async throws -> Data {
        let email = try encrypt(from: username)
        let password = try encrypt(from: passwordOri)
        var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.login())!)
        req.setHost(host: "homa.snapgenshin.com")
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let result = try await req.receiveOrThrowHutao(isPost: true, reqBody: try! JSONSerialization.data(withJSONObject: [
            "UserName": email, "Password": password]))
        if writeKeychain {
            if save2keychain(entry: HutaoPassportStruct(username: username, password: passwordOri)) == errSecSuccess {
                UserDefaults.standard.set(true, forKey: TBData.USE_KEY_CHAIN)
                UserDefaults.standard.set(username, forKey: TBData.KEY_CHAIN_NAME)
                UserDefaults.standard.set(Int(Date().timeIntervalSince1970), forKey: "hutaoLastLogin")
            } else {
                UserDefaults.standard.set(false, forKey: TBData.USE_KEY_CHAIN)
            }
        } else {
            UserDefaults.standard.set(Int(Date().timeIntervalSince1970), forKey: "hutaoLastLogin")
        }
        return result
    }
    
    /// 获取通行证信息
    static func userInfo(auth: String) async throws -> Data {
        var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.userInfo())!)
        req.setHost(host: "homa.snapgenshin.com")
        req.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")
        return try await req.receiveOrThrow().rawData()
    }
}

// 与祈愿记录沟通的部分
extension TBHutaoService {
    /// 获取上传的抽卡记录信息
    static func gachaEntries(hutao: HutaoPassport) async throws -> Data {
        var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.gachaEntries())!)
        req.setHost(host: "homa.snapgenshin.com")
        req.setValue("Bearer \(hutao.auth)", forHTTPHeaderField: "Authorization")
        return try await req.receiveOrThrow().rawData()
    }
    
    /// 删除云祈愿记录
    static func deleteGachaRecord(uid: String, hutao: HutaoPassport) async throws -> Data {
        var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.gachaDelete(uid: uid))!)
        req.setHost(host: "homa.snapgenshin.com")
        req.setValue("Bearer \(hutao.auth)", forHTTPHeaderField: "Authorization")
        return try await req.receiveOrThrowHutao()
    }
    
    /// 获取云端每个卡池的最新值 用于增量更新的判断
    static func fetchRecordEndIDs(uid: String, hutao: String) async throws -> Data {
        var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.gachaEndIds(uid: uid))!)
        req.setHost(host: "homa.snapgenshin.com")
        req.setValue("Bearer \(hutao)", forHTTPHeaderField: "Authorization")
        return try await req.receiveOrThrowHutao()
    }
    
    /// 上传祈愿数据 由于胡桃云遵循增量上传规则，故需要进行本地与云端数据比对，但如果云端没有数据时则全量上传。
    static func uploadGachaRecord(records: Data, uid: String, hutao: String) async throws -> Data {
        var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.gachaUpload())!)
        req.setHost(host: "homa.snapgenshin.com")
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(hutao)", forHTTPHeaderField: "Authorization")
        req.setValue("\(records.count)", forHTTPHeaderField: "Content-Length")
        return try await req.receiveOrThrowHutao(isPost: true, reqBody: records)
    }
}
