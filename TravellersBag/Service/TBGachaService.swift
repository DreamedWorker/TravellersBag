//
//  TBGachaService.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/12/9.
//

import Foundation
import SwiftyJSON

class TBGachaService {
    
    /// 返回 AuthKeyB 字符串（抽卡分析用途）
    static func getAuthKeyB(user: MihoyoAccount) async throws -> String {
        let reqBody = try! JSONSerialization.data(withJSONObject: [
            "auth_appid": "webview_gacha", "game_biz": "hk4e_cn", "game_uid": Int(user.gameInfo.genshinUID)!, "region": user.gameInfo.serverRegion
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
    
    /// 查询指定卡池的数据
    static func getGachaInfo(gachaType: String, authKey: String, endID: String = "0") async throws -> [JSON] {
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
        
        try await fetchData(gachaType: gachaType, authKey: authKey, endID: endID)
        return partData
    }
    
    /// 获取物品的名字和星级 返回格式：物品名字@星级@类型
    /// 如果没有数据，则返回：???@3@?
    static func getItemChineseName(itemId: String) -> String {
        let name = ResHandler.default.getGachaItemName(key: itemId)
        let rank = ResHandler.default.getItemRank(key: itemId)
        if itemId.count == 5 { // 武器
            return "\(name)@\(rank)@武器"
        } else if itemId.count == 8 { // 角色
            return "\(name)@\(rank)@角色"
        } else {
            return "???@3@?"
        }
    }
}
