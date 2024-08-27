//
//  GachaService.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/23.
//

import Foundation

/// 抽卡分析页服务
class GachaService {
    private init() {}
    static let shared = GachaService()
    
    /// 返回 AuthKeyB 字符串（抽卡分析用途）
    func getAuthKeyB(user: ShequAccount) async throws -> String {
        let reqBody = try! JSONSerialization.data(withJSONObject: [
            "auth_appid": "webview_gacha", "game_biz": "hk4e_cn", "game_uid": Int(user.genshinUID!)!, "region": user.serverRegion!
        ])
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getAuthKey())!)
        req.setHost(host: "api-takumi.mihoyo.com")
        req.setUser(singleUser: user)
        req.setDeviceInfoHeaders()
        req.setReferer(referer: "https://app.mihoyo.com/")
        req.setDS(version: SaltVersion.V1, type: SaltType.LK2)
        req.setXRPCAppInfo(client: "5")
        req.setIosUA()
        let result = try await req.receiveOrThrow(isPost: true, reqBody: reqBody)
        return result["authkey"].stringValue
    }
    
    func getGachaInfo(gachaType: String, authKey: String, endID: String = "0") async throws -> [JSON] {
        var partData: [JSON] = [] // 用于存储累计的数据
        
        func fetchData(gachaType: String, authKey: String, endID: String = "0") async throws {
            var req = URLRequest(url: URL(string: ApiEndpoints.shared.getGachaData(key: authKey, type: Int(gachaType)!, endID: Int(endID)!))!)
            req.setValue("okhttp/4.9.3", forHTTPHeaderField: "user-agent")
            let result = try await req.receiveOrThrow()
            let partList = result["list"].arrayValue
            partData.append(contentsOf: partList)
            if partList.count == 20 {
                try await Task.sleep(for: .seconds(1.5))
                try await fetchData(gachaType: gachaType, authKey: authKey, endID: partList.last!["id"].stringValue)
            }
        }
        
        try await fetchData(gachaType: gachaType, authKey: authKey)
        return partData
    }
}
