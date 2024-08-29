//
//  HutaoService.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/29.
//

import Foundation
import CryptoKit

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
    
    /// 获取通行证信息
    func userInfo(auth: String) async throws -> JSON {
        var req = URLRequest(url: URL(string: HutaoApiEndpoints.shared.userInfo())!)
        req.setHost(host: "homa.snapgenshin.com")
        req.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")
        return try await req.receiveOrThrow()
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
