//
//  TBHutaoService.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/5.
//

import Foundation
import SwiftyJSON

// 账号登录的部分
class TBHutaoService {
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
    
    static func loginPassport(username: String, password: String) async throws -> JSON {
        let email = try encrypt(from: username)
        let password = try encrypt(from: password)
        var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.login())!)
        req.setHost(host: "homa.snapgenshin.com")
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let result = try await req.receiveOrThrowHutao(isPost: true, reqBody: try! JSONSerialization.data(withJSONObject: [
            "UserName": email, "Password": password]))
        if self.save2keychain(entry: self.HutaoPassportStruct(username: username, password: password)) != noErr {
            UserDefaults.configSetValue(key: TBData.USE_KEY_CHAIN, data: true)
            UserDefaults.configSetValue(key: TBData.KEY_CHAIN_NAME, data: username)
            UserDefaults.configSetValue(key: "hutaoLastLogin", data: Int(Date().timeIntervalSince1970))
        } else {
            UserDefaults.configSetValue(key: TBData.USE_KEY_CHAIN, data: false)
        }
        return result
    }
    
    /// 获取通行证信息
    static func userInfo(auth: String) async throws -> JSON {
        var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.userInfo())!)
        req.setHost(host: "homa.snapgenshin.com")
        req.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")
        return try await req.receiveOrThrow()
    }
}

// 与系统「钥匙串访问」沟通的部分
extension TBHutaoService {
    struct HutaoPassportStruct {
        var username: String // 用户名：可以是电话号码也可以是邮箱
        var password: String // 密码
    }
    
    static let service = "icu.bluedream.TravellersBag"
    
    static func save2keychain(entry: HutaoPassportStruct) -> OSStatus {
        let passwordItem = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : entry.username,
            kSecAttrService as String : service,
            kSecValueData as String   : entry.password.data(using: .utf8)!,
            ] as [String : Any]
        return SecItemAdd(passwordItem as CFDictionary, nil)
    }
}

// 与祈愿记录沟通的部分
extension TBHutaoService {
    /// 获取上传的抽卡记录信息
    static func gachaEntries(hutao: HutaoPassport) async throws -> JSON {
        var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.gachaEntries())!)
        req.setHost(host: "homa.snapgenshin.com")
        req.setValue("Bearer \(hutao.auth)", forHTTPHeaderField: "Authorization")
        return try await req.receiveOrThrow()
    }
    
    /// 删除云祈愿记录
    static func deleteGachaRecord(uid: String, hutao: HutaoPassport) async throws -> JSON {
        var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.gachaDelete(uid: uid))!)
        req.setHost(host: "homa.snapgenshin.com")
        req.setValue("Bearer \(hutao.auth)", forHTTPHeaderField: "Authorization")
        return try await req.receiveOrThrowHutao()
    }
}
