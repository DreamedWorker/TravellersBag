//
//  AvatarService.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/3.
//

import Foundation
import SwiftyJSON

class AvatarService {
    private init() {}
    static let `defalult` = AvatarService()
    
    /// 获取战绩面板的全部角色列表
    func fetchCharacterList(user: ShequAccount) async throws -> JSON {
        let reqBody = """
{
"sort_type": 1, "role_id": "\(user.genshinUID!)", "server": "cn_gf01"
}
"""
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getAvatarList())!)
        req.setHost(host: "api-takumi-record.mihoyo.com")
        req.setReferer(referer: "https://webstatic.mihoyo.com/")
        req.setIosUA()
        req.setDeviceInfoHeaders()
        req.setXRPCAppInfo(client: "5")
        req.setValue(
            "account_id=\(user.stuid!);cookie_token=\(user.cookieToken!);ltoken=\(user.ltoken!);ltuid=\(user.stuid!)",
            forHTTPHeaderField: "cookie"
        )
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.setDS(version: .V2, type: .X4, body: reqBody, include: false)
        return try await req.receiveOrThrow(isPost: true, reqBody: reqBody.data(using: .utf8)!)
    }
    
    func fetchCharacterDetail(user: ShequAccount, list: JSON) async throws -> JSON {
        var avatarsIds: [Int] = []
        for i in list["list"].arrayValue {
            avatarsIds.append(i["id"].intValue)
        }
        let reqBody = """
{
"sort_type": 1, "character_ids": \(avatarsIds), "role_id": "\(user.genshinUID!)", "server": "cn_gf01"
}
"""
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getAvatarDetail())!)
        req.setHost(host: "api-takumi-record.mihoyo.com")
        req.setReferer(referer: "https://webstatic.mihoyo.com/")
        req.setIosUA()
        req.setDeviceInfoHeaders()
        req.setXRPCAppInfo(client: "5")
        req.setValue(
            "account_id=\(user.stuid!);cookie_token=\(user.cookieToken!);ltoken=\(user.ltoken!);ltuid=\(user.stuid!)",
            forHTTPHeaderField: "cookie"
        )
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.setDS(version: .V2, type: .X4, body: reqBody, include: false)
        return try await req.receiveOrThrow(isPost: true, reqBody: reqBody.data(using: .utf8)!)
    }
}
