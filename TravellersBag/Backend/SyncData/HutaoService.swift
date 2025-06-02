//
//  HutaoService.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/6/2.
//

import Foundation

// MARK: - 登录部分
class HutaoService {
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
            throw NSError(domain: "SyncService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: String.localizedStringWithFormat(
                    NSLocalizedString("sync.error.crypto", comment: ""), "\(error!.takeRetainedValue() as Error)")
            ])
        }
        return encryptedData.base64EncodedString()
    }
    
    static func tryLogin(username: String, password: String) async throws -> String {
        let email = try encrypt(from: username)
        let password = try encrypt(from: password)
        var loginRequest = RequestBuilder.buildRequest(
            method: .POST, host: Endpoints.HomaSnapGenshin, path: "/Passport/Login",
            queryItems: [],
            body: try JSONSerialization.data(withJSONObject: ["UserName": email, "Password": password])
        )
        loginRequest.setValue("homa.snapgenshin.com", forHTTPHeaderField: "Host")
        loginRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let result = try await NetworkClient.simpleDataClient(request: loginRequest, type: PassportLoginResult.self)
        if result.retcode != 0 {
            throw NSError(domain: "SyncService", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "Failed to login, \(result.message)"
            ])
        } else {
            return result.data
        }
    }
    
    static func fetchUserInfo(auth: String) async throws -> HutaoPpDetail {
        var detailRequest = RequestBuilder.buildRequest(
            method: .GET, host: Endpoints.HomaSnapGenshin, path: "/Passport/UserInfo", queryItems: []
        )
        detailRequest.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")
        let result = try await NetworkClient.simpleDataClient(request: detailRequest, type: HutaoPpDetail.self)
        if result.retcode != 0 {
            throw NSError(domain: "SyncService", code: -3, userInfo: [
                NSLocalizedDescriptionKey: "Failed to fetch user info, \(result.message)"
            ])
        } else {
            return result
        }
    }
}

extension HutaoService {
    struct PassportLoginResult: Codable {
        let data: String
        let retcode: Int
        let message: String
    }
}

extension HutaoService {
    struct HutaoPpDetail: Codable {
        let data: DataClass
        let retcode: Int
        let message: String
    }
}

extension HutaoService.HutaoPpDetail {
    struct DataClass: Codable {
        let normalizedUserName, userName: String
        let isLicensedDeveloper, isMaintainer: Bool
        let gachaLogExpireAt, cdnExpireAt: String

        enum CodingKeys: String, CodingKey {
            case normalizedUserName = "NormalizedUserName"
            case userName = "UserName"
            case isLicensedDeveloper = "IsLicensedDeveloper"
            case isMaintainer = "IsMaintainer"
            case gachaLogExpireAt = "GachaLogExpireAt"
            case cdnExpireAt = "CdnExpireAt"
        }
    }
}

// MARK: - 祈愿部分
extension HutaoService {
    static func fetchGachaEntries(auth: String) async throws -> HutaoGachaEntry {
        var gachaRequest = RequestBuilder.buildRequest(
            method: .GET, host: Endpoints.HomaSnapGenshin, path: "/GachaLog/Entries", queryItems: []
        )
        gachaRequest.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")
        let result = try await NetworkClient.simpleDataClient(request: gachaRequest, type: HutaoGachaEntry.self)
        if result.retcode != 0 {
            throw NSError(domain: "SyncService", code: -4, userInfo: [
                NSLocalizedDescriptionKey: "Failed to fetch gahca cloud records, \(result.message)"
            ])
        } else {
            return result
        }
    }
    
    static func getEndIds(auth: String, uid: String) async throws -> GachaEndIDS {
        var endIdRequest = RequestBuilder.buildRequest(
            method: .GET, host: Endpoints.HomaSnapGenshin, path: "/GachaLog/EndIds", queryItems: [
                .init(name: "Uid", value: uid)
            ]
        )
        endIdRequest.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")
        let result = try await NetworkClient.simpleDataClient(request: endIdRequest, type: GachaEndIDS.self)
        if result.retcode != 0 {
            throw NSError(domain: "SyncService", code: -5, userInfo: [
                NSLocalizedDescriptionKey: "Failed to fetch gahca record's endID, \(result.message)"
            ])
        } else {
            return result
        }
    }
    
    static func fetchRecords(auth: String, uid: String) async throws -> GachaCloudRecord {
        let endIDs = try await getEndIds(auth: auth, uid: uid)
        let requestBody = """
{
"Uid": "\(uid)", 
"EndIds": {
"100": \(Int(endIDs.data["100"]!)), 
"200": \(Int(endIDs.data["200"]!)),
"301": \(Int(endIDs.data["301"]!)),
"302": \(Int(endIDs.data["302"]!)),
"500": \(Int(endIDs.data["500"]!))
}
}
""".data(using: .utf8)
        var recordRequest = RequestBuilder.buildRequest(
            method: .POST, host: Endpoints.HomaSnapGenshin, path: "/GachaLog/Retrieve", queryItems: [],
            body: requestBody
        )
        recordRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        recordRequest.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")
        let result = try await NetworkClient.simpleDataClient(request: recordRequest, type: GachaCloudRecord.self)
        if result.retcode != 0 {
            throw NSError(domain: "SyncService", code: -6, userInfo: [
                NSLocalizedDescriptionKey: "Failed to fetch gahca record's stored in cloud, \(result.message)"
            ])
        } else {
            return result
        }
    }
}

extension HutaoService {
    struct HutaoGachaEntry: Codable {
        let data: [Datum]
        let retcode: Int
        let message: String
    }
}

extension HutaoService.HutaoGachaEntry {
    struct Datum: Codable, Identifiable {
        let id: String = UUID().uuidString
        let uid: String
        let excluded: Bool
        let itemCount: Int

        enum CodingKeys: String, CodingKey {
            case uid = "Uid"
            case excluded = "Excluded"
            case itemCount = "ItemCount"
        }
    }
}

extension HutaoService {
    struct GachaEndIDS: Codable {
        let data: [String: Double]
        let retcode: Int
        let message: String
    }
}

extension HutaoService {
    struct GachaCloudRecord: Codable {
        let data: [Datum]
        let retcode: Int
        let message: String
    }
}

extension HutaoService.GachaCloudRecord {
    struct Datum: Codable {
        let gachaType, queryType, itemID: Int
        let time: String
        let id: Int

        enum CodingKeys: String, CodingKey {
            case gachaType = "GachaType"
            case queryType = "QueryType"
            case itemID = "ItemId"
            case time = "Time"
            case id = "Id"
        }
    }
}
