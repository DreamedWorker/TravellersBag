//
//  AvatarService.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/3.
//

import Foundation
@preconcurrency import SwiftyJSON

class AvatarService: @unchecked Sendable {
    private init() {}
    static let `defalult` = AvatarService()
    
    /// 获取战绩面板的全部角色列表
    @MainActor func fetchCharacterList(user: MihoyoAccount) async throws -> JSON {
        let reqBody = """
{
"sort_type": 1, "role_id": "\(user.gameInfo.genshinUID)", "server": "cn_gf01"
}
"""
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getAvatarList())!)
        req.setHost(host: "api-takumi-record.mihoyo.com")
        req.setReferer(referer: "https://webstatic.mihoyo.com/")
        req.setIosUA()
        req.setDeviceInfoHeaders()
        req.setXRPCAppInfo(client: "5")
        req.setValue(
            "account_id=\(user.cookies.stuid);cookie_token=\(user.cookies.cookieToken);ltoken=\(user.cookies.ltoken);ltuid=\(user.cookies.stuid)",
            forHTTPHeaderField: "cookie"
        )
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.setDS(version: .V2, type: .X4, body: reqBody, include: false)
        return try await req.receiveOrThrow(isPost: true, reqBody: reqBody.data(using: .utf8)!)
    }
    
    @MainActor func fetchCharacterDetail(user: MihoyoAccount, list: JSON) async throws -> JSON {
        var avatarsIds: [Int] = []
        for i in list["list"].arrayValue {
            avatarsIds.append(i["id"].intValue)
        }
        let reqBody = """
{
"sort_type": 1, "character_ids": \(avatarsIds), "role_id": "\(user.gameInfo.genshinUID)", "server": "cn_gf01"
}
"""
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getAvatarDetail())!)
        req.setHost(host: "api-takumi-record.mihoyo.com")
        req.setReferer(referer: "https://webstatic.mihoyo.com/")
        req.setIosUA()
        req.setDeviceInfoHeaders()
        req.setXRPCAppInfo(client: "5")
        req.setValue(
            "account_id=\(user.cookies.stuid);cookie_token=\(user.cookies.cookieToken);ltoken=\(user.cookies.ltoken);ltuid=\(user.cookies.stuid)",
            forHTTPHeaderField: "cookie"
        )
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.setDS(version: .V2, type: .X4, body: reqBody, include: false)
        return try await req.receiveOrThrow(isPost: true, reqBody: reqBody.data(using: .utf8)!)
    }
}
