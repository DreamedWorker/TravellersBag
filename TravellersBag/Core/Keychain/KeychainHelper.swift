//
//  KeychainHelper.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/11.
//

import Foundation

// 与系统「钥匙串访问」沟通的部分
extension TBHutaoService {
    
    static func save2keychain(entry: HutaoPassportStruct) -> OSStatus {
        let passwordItem = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : entry.username,
            kSecAttrService as String : tbService,
            kSecValueData as String   : entry.password.data(using: .utf8)!,
            ] as [String : Any]
        return SecItemAdd(passwordItem as CFDictionary, nil)
    }
    
    static func read4keychain(username: String) throws -> HutaoPassportStruct {
        let query = [
            kSecClass as String : kSecClassGenericPassword,
            kSecAttrService as String : tbService,
            kSecAttrAccount as String : username,
            kSecReturnData as String : true,
            kSecMatchLimit as String : kSecMatchLimitOne,
            kSecReturnAttributes as String : true
        ] as [String : Any]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else { throw KeychainError.noPassword }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
        guard let existingItem = item as? [String : Any],
              let passwordData = existingItem[kSecValueData as String] as? Data,
              let password = String(data: passwordData, encoding: String.Encoding.utf8),
              let account = existingItem[kSecAttrAccount as String] as? String
        else {
            throw KeychainError.unexpectedPasswordData
        }
        return HutaoPassportStruct(username: account, password: password)
    }
}
