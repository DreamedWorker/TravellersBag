//
//  GachaHelper.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/29.
//

import Foundation

class GachaHelper {
    static func getAuthKeyB(_ user: HoyoAccount) async throws -> String {
        var keyRequest = RequestBuilder.buildRequest(
            method: .POST, host: Endpoints.TakumiMiyousheApi, path: "/binding/api/genAuthKey", queryItems: [],
            body: try! JSONSerialization.data(withJSONObject: [
                "auth_appid": "webview_gacha", "game_biz": "hk4e_cn", "game_uid": Int(user.game.genshinUID)!, "region": user.game.serverRegion
            ]),
            optHost: "api-takumi.mihoyo.com", referer: "https://app.mihoyo.com/",
            user: RequestBuilder.RequestingUser(uid: user.cookie.stuid, stoken: user.cookie.stoken, mid: user.cookie.mid),
            ds: DynamicSecret.getDynamicSecret(version: .V1, saltType: .LK2)
        )
        [
            "x-rpc-app_id": "bll8iq97cem8",
            "x-rpc-client_type": "5",
            "x-rpc-app_version": "2.71.1",
        ].forEach { (key: String, value: String) in
            keyRequest.addValue(value, forHTTPHeaderField: key)
        }
        let value = try await NetworkClient.simpleDataClient(request: keyRequest, type: AuthKeyStruct.self)
        if value.retcode != 0 {
            throw NSError(domain: "GachaHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get AuthKey, \(value.message)"])
        }
        return value.data.authkey
    }
    
    static func getGachaInfo(gachaType: String, authKey: String, endID: String = "0") async throws -> [GachaList.GachaListData.GachaItems] {
        var tempList: [GachaList.GachaListData.GachaItems] = []
        var key = authKey
        key = key.replacingOccurrences(of: "+", with: "%2B")
        key = key.replacingOccurrences(of: "/", with: "%2F")
        key = key.replacingOccurrences(of: "=", with: "%3D")
        func fetchData(gachaType: String, authedKey: String, endID: String = "0") async throws {
            let url = "https://public-operation-hk4e.mihoyo.com/gacha_info/api/getGachaLog?lang=zh-cn&auth_appid=webview_gacha&authkey=\(key)&authkey_ver=\(1)&sign_type=\(2)&gacha_type=\(gachaType)&size=\(20)&end_id=\(endID)"
            var gachaRequest = URLRequest(url: URL(string: url)!)
            gachaRequest.setValue("okhttp/4.9.3", forHTTPHeaderField: "user-agent")
            let result = try await NetworkClient.simpleDataClient(request: gachaRequest, type: GachaList.self)
            if result.retcode != 0 {
                throw NSError(domain: "GachaHelper", code: -2, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to get gacha recorder for url: \(url), because: \(result.message)"
                ])
            }
            result.data.list.forEach { single in
                tempList.append(single)
            }
            if result.data.list.count == 20 {
                try await Task.sleep(for: .seconds(1.5))
                try await fetchData(gachaType: gachaType, authedKey: key, endID: result.data.list.last!.id)
            }
        }
        
        try await fetchData(gachaType: gachaType, authedKey: key, endID: endID)
        return tempList
    }
}

// MARK: - Auth Key B
extension GachaHelper {
    struct AuthKeyStruct: Codable {
        let retcode: Int
        let message: String
        let data: KeyStruct
    }
}

extension GachaHelper.AuthKeyStruct {
    struct KeyStruct: Codable {
        let authkey: String
    }
}

// MARK: - Gacha Items
extension GachaHelper {
    struct GachaList: Codable {
        let retcode: Int
        let message: String
        let data: GachaListData
    }
}

extension GachaHelper.GachaList {
    struct GachaListData: Codable {
        let page, size, total: String
        let list: [GachaItems]
        let region: String
    }
}

extension GachaHelper.GachaList.GachaListData {
    struct GachaItems: Codable {
        let uid, gachaType, itemID, count: String
        let time, name: String
        let itemType: ItemType
        let rankType, id: String

        enum CodingKeys: String, CodingKey {
            case uid
            case gachaType = "gacha_type"
            case itemID = "item_id"
            case count, time, name
            case itemType = "item_type"
            case rankType = "rank_type"
            case id
        }
    }

    enum ItemType: String, Codable {
        case 武器 = "武器"
        case 角色 = "角色"
    }
}
