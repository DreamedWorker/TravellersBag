//
//  AccountService.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/17.
//

import Foundation
import SwiftyJSON

/// 账号相关的单例服务类
class AccountService {
    static let shared = AccountService()
    private init() {}
    
    /// 获取一个二维码链接。
    func fetchQRCode() async throws -> String {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getFetchQRCode())!)
        let result = try await req.receiveOrThrow(
            isPost: true,
            reqBody: try! JSONSerialization.data(
                withJSONObject: ["app_id": "2", "device": UserDefaultHelper.shared.getValue(forKey: TBEnv.DEVICE_ID, def: "")]
            )) // 使用原神的ID请求到的二维码因为技术原因在扫描后会报安全错误，故采用此。
        return result["url"].stringValue
    }
    
    /// 查询指定ticket的二维码扫描状态
    /// 如果成功则返回一个可转为json的Data数据，包含水社ID和游戏Token
    func queryCodeState(ticket: String) async throws -> Data {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getQueryQRState())!)
        let result = try await req.receiveOrThrow(
            isPost: true,
            reqBody: try! JSONSerialization.data(
                withJSONObject: [
                    "app_id": "2", "device": UserDefaultHelper.shared.getValue(forKey: TBEnv.DEVICE_ID, def: ""), "ticket": ticket
                ]
            ))
        if result["stat"].stringValue != "Confirmed" {
            throw TBErrors.qrCodeStateError(
                String.localizedStringWithFormat(
                    NSLocalizedString("account.error.qrcode_state_err", comment: ""), result["stat"].stringValue)
            )
        }
        let futherData = try JSON(data: result["payload"]["raw"].stringValue.data(using: .utf8)!)
        return try! JSONSerialization.data(withJSONObject: [
            "uid": futherData["uid"].stringValue, "game_token": futherData["token"].stringValue
        ])
    }
    
    /// 通过GameToken获取SToken
    /// - Returns:
    ///   - EventMessager: 如果成功，返回一个可转为JSON的值，包含stuid, stoken, mid
    func pullUserSToken(uid: String, token: String) async throws -> Data {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getSTokenByGameToken())!)
        req.setValue("bll8iq97cem8", forHTTPHeaderField: "x-rpc-app_id")
        let result = try await req.receiveOrThrow(
            isPost: true, reqBody: try! JSONSerialization.data(withJSONObject: [
                "account_id": Int(uid)!, "game_token": token
            ]))
        return try! JSONSerialization.data(withJSONObject: [
            "stuid": result["user_info"]["aid"].stringValue, "stoken": result["token"]["token"].stringValue,
            "mid": result["user_info"]["mid"].stringValue
        ])
    }
    
    /// 通过GameToken获取CookieToken
    func pullUserCookieToken(uid: String, token: String) async throws -> String {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getCookieToken(aid: Int(uid)!, token: token))!)
        let result = try await req.receiveOrThrow()
        return result["cookie_token"].stringValue
    }
    
    /// 获取用户的水社昵称和头像 成功则返回一个JSON的Data
    func pullUserSheInfo(uid: String) async throws -> Data {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getSheUserInfo(uid: uid))!)
        let result = try await req.receiveOrThrow()
        return try! JSONSerialization.data(withJSONObject: [
            "nickname": result["user_info"]["nickname"].stringValue,
            "avatar_url": result["user_info"]["avatar_url"].stringValue.replacingOccurrences(of: "\\", with: "")
        ])
    }
    
    /// 获取用户原神的基本数据 成功则返回一个包含服务器、服务器名称、原神uid的jsonData
    func pullHk4eBasic(uid: String, stoken: String, mid: String) async throws -> Data {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getGameBasic())!)
        req.setHost(host: "api-takumi.miyoushe.com")
        req.setReferer(referer: "https://app.mihoyo.com")
        req.setValue("https://api-takumi.miyoushe.com", forHTTPHeaderField: "Origin")
        req.setIosUA()
        req.setDS(version: SaltVersion.V1, type: SaltType.K2)
        req.setDeviceInfoHeaders()
        req.setUser(uid: uid, stoken: stoken, mid: mid)
        req.setXRPCAppInfo()
        req.setXRequestWith()
        let result = try await req.receiveOrThrow()
        let role = result["list"].arrayValue.filter({$0["game_biz"].stringValue == "hk4e_cn"}).first
        if let role = role {
            return try! JSONSerialization.data(withJSONObject: [
                "region": role["region"].stringValue,
                "genshinName": role["region_name"].stringValue,
                "genshinUid": role["game_uid"].stringValue,
                "level": String(role["level"].intValue),
                "genshinNicname": role["nickname"].stringValue
            ])
        } else {
            throw NSError(domain: "account.query.kh4e_info", code: -1, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("account.service.cannot_copy_hk4e_detail", comment: "")
            ])
        }
    }
    
    /// 获取用户的Ltoken
    func pullUserLtoken(uid: String, stoken: String, mid: String) async throws -> String {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getLTokenBySToken())!)
        req.setUser(uid: uid, stoken: stoken, mid: mid)
        let result = try await req.receiveOrThrow()
        return result["ltoken"].stringValue
    }
    
    /// 将从镜像站获取到的数据写入本地，然后返回头像ID用于CoreData存储。
    func pullAndPutGameInfo(uid: String) async throws -> String {
        let result = try await CharacterService.shared.pullCharactersFromEnka(gameUID: uid)
        let charactersFromEnka = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(component: "characters_from_enka-\(uid).json").path().removingPercentEncoding!
        if !FileManager.default.fileExists(atPath: charactersFromEnka) {
            FileManager.default.createFile(atPath: charactersFromEnka, contents: nil)
        } else {
            FileHandler.shared.writeUtf8String(path: charactersFromEnka, context: "")
        }
        FileHandler.shared.writeUtf8String(path: charactersFromEnka, context: String(data: result, encoding: .utf8)!)
        let json = try JSON(data: result)
        return String(json["playerInfo"]["profilePicture"]["id"].intValue)
    }
    
    /// 通过Stoken获取CookieToken
    func pullUserCookieToken(uid: String, stoken: String, mid: String) async throws -> String {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getCookieTokenByStoken())!)
        req.setValue("stoken=\(stoken)==.CAE=;mid=\(mid)", forHTTPHeaderField: "Cookie")
        // 写的时候没有注意到split方法把token的尾部给干掉了，难怪之前一直调不通
        req.setDS(version: SaltVersion.V2, type: SaltType.PROD)
        req.setDeviceInfoHeaders()
        req.setXRPCAppInfo()
        req.setValue("okhttp/4.9.3", forHTTPHeaderField: "User-Agent")
        req.setValue("bbs_cn", forHTTPHeaderField: "x-rpc-game_biz")
        req.setValue("2.20.2", forHTTPHeaderField: "x-rpc-sdk_version")
        req.setValue("2.20.2", forHTTPHeaderField: "x-rpc-account_version")
        req.setValue(UUID().uuidString.lowercased(), forHTTPHeaderField: "x-rpc-lifecycle_id")
        req.setHost(host: "passport-api.mihoyo.com")
        let result = try await req.receiveOrThrow()
        return result["cookie_token"].stringValue
    }
    
    /// 通过Stoken获取GameToken
    func pullUserGameToken(stoken: String, mid: String) async throws -> String {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getGameTokenByStoken())!)
        req.setValue("stoken=\(stoken)==.CAE=;mid=\(mid)", forHTTPHeaderField: "Cookie")
        let result = try await req.receiveOrThrow()
        return result["game_token"].stringValue
    }
}
