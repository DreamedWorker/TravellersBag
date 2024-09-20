//
//  SecurityTool.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/29.
//

import Foundation
import Security

/// 用于向钥匙串存储账密的结构体
struct TravellersAccount { // 这个结构体存储的数据是明文的
    var username: String // 用户名：可以是电话号码也可以是邮箱
    var password: String // 密码
}

/// 旅者行囊与钥匙串通信的工具类
class SecurityTool {
    static let shared = SecurityTool()
    private init() {}
    let server = "bluedream.icu"
    
    /// 保存密码 会尝试删除旧的 如果存在的话
    func save(account: TravellersAccount) -> OSStatus {
        let query = [
            kSecClass as String : kSecClassGenericPassword,
            kSecAttrService as String : server,
            kSecAttrAccount as String : account.username,
            kSecValueData as String : account.password.data(using: .utf8)!,
            kSecAttrAccessible as String : kSecAttrAccessibleWhenUnlocked
        ] as [CFString : Any]
        SecItemDelete(query as CFDictionary)
        let state = SecItemAdd(query as CFDictionary, nil)
        return state
    }
    
    /// 根据用户名读取密码
    func read(key: String) throws -> TravellersAccount {
        let query = [
            kSecClass as String : kSecClassGenericPassword,
            kSecAttrService as String : server,
            kSecAttrAccount as String : key,
            kSecReturnData as String : kCFBooleanTrue ?? true,
            kSecMatchLimit as String : kSecMatchLimitOne
        ] as [CFString : Any]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == noErr, let data = result as? Data else {
            throw NSError(domain: "app.security", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "无法获取对应的钥匙串值"
            ])
        }
        return TravellersAccount(username: key, password: String(data: data, encoding: .utf8)!)
    }
}
