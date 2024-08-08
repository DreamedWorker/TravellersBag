//
//  AccountService.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/6.
//

import Foundation
import MMKV

/// 账号相关的单例服务类
class AccountService {
    static let shared = AccountService()
    private let envKV = MMKV.default()!
    
    /// 获取一个二维码链接。
    func fetchQRCode() async throws -> String {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getFetchQRCode())!)
        let result = try await req.receiveOrThrow(
            isPost: true,
            reqBody: try! JSONSerialization.data(
                withJSONObject: ["app_id": "2", "device": envKV.string(forKey: LocalEnvironment.DEVICE_ID)!]
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
                withJSONObject: ["app_id": "2", "device": envKV.string(forKey: LocalEnvironment.DEVICE_ID)!, "ticket": ticket]
            ))
        if result["stat"].stringValue != "Confirmed" {
            throw NSError(
                domain: "account.query.qrcode",
                code: -106,
                userInfo: [
                    NSLocalizedDescriptionKey: String.localizedStringWithFormat(NSLocalizedString("account.service.qrcode_state_err", comment: ""), result["stat"].stringValue)
                ])
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
//        do {
//            let json = try JSON(data: gameTokenData.data(using: .utf8)!) // 吐槽一下下面两行 一段json埋这么深干嘛
//            let innerJSON = try JSON(data: json["data"]["payload"]["raw"].stringValue.data(using: .utf8)!)
//            let sheID = innerJSON["uid"].stringValue
//            let gameToken = innerJSON["token"].stringValue
//            var req = URLRequest(url: URL(string: ApiEndpoints.shared.getSTokenByGameToken())!)
//            req.setValue("bll8iq97cem8", forHTTPHeaderField: "x-rpc-app_id")
//            let result = await req.receiveData(
//                session: httpSession(),
//                isPost: true,
//                reqBody: try! JSONSerialization.data(withJSONObject: ["account_id": Int(sheID)!, "game_token": gameToken]))
//            if result.evtState {
//                let data = result.data as! String
//                if data.contains("OK") {
//                    // 先拿到数据 关于头像和绑定的原神数据什么的 之后再通过判断对应参数是否为空来获取
//                    let tokenJSON = try JSON(data: data.data(using: .utf8)!)
//                    let stoken = tokenJSON["data"]["token"]["token"].stringValue
//                    let stuid = tokenJSON["data"]["user_info"]["aid"].stringValue // aid实际上就是stuid 就是米社id
//                    let mid = tokenJSON["data"]["user_info"]["mid"].stringValue
//                    return EventMessager(evtState: true, data: HoyoUser(stuid: stuid, stoken: stoken, mid: mid))
//                } else {
//                    return EventMessager(evtState: false, data: data)
//                }
//            } else {
//                return EventMessager(evtState: false, data: "pullUserSToken:\(result.data as! String)")
//            }
//        } catch {
//            return EventMessager(evtState: false, data: "pullUserSToken:\(error.localizedDescription)")
//        }
    }
    
    func pullUserCookieToken(uid: String, token: String) async throws -> String {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getCookieToken(aid: Int(uid)!, token: token))!)
        let result = try await req.receiveOrThrow()
        return result["cookie_token"].stringValue
    }
    
    /// 获取用户的Ltoken
    func pullUserLtoken(uid: String, stoken: String, mid: String) async throws -> String {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getLTokenBySToken())!)
        req.setUser(uid: uid, stoken: stoken, mid: mid)
        let result = try await req.receiveOrThrow()
        return result["ltoken"].stringValue
//        req.setUser(singleUser: user)
//        let result = await req.receiveData(session: httpSession(), reqBody: nil)
//        if result.evtState {
//            let data = result.data as! String
//            if data.contains("OK") {
//                do {
//                    let json = try JSON(data: data.data(using: .utf8)!)
//                    return EventMessager(evtState: true, data: json["data"]["ltoken"].stringValue)
//                } catch {
//                    return EventMessager(evtState: false, data: error.localizedDescription)
//                }
//            } else {
//                return EventMessager(evtState: false, data: "服务器返回数据异常，请重新登录或检查网络。")
//            }
//        } else {
//            return result
//        }
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
        req.setUA()
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
                "level": String(role["level"].intValue)
            ])
        } else {
            throw NSError(domain: "account.query.kh4e_info", code: -1, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("account.service.cannot_copy_hk4e_detail", comment: "")
            ])
        }
        
//        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getGameBasic())!)
//        req.setHost(host: "api-takumi.miyoushe.com")
//        req.setReferer(referer: "https://app.mihoyo.com")
//        req.setValue("https://api-takumi.miyoushe.com", forHTTPHeaderField: "Origin")
//        req.setUA()
//        req.setDS(version: SaltVersion.V1, type: SaltType.K2)
//        req.setDeviceInfoHeaders()
//        req.setUser(singleUser: user)
//        req.setXRPCAppInfo()
//        req.setXRequestWith()
//        let result = await req.receiveData(session: httpSession(), reqBody: nil)
//        if result.evtState {
//            let data = result.data as! String
//            if data.contains("OK") {
//                do {
//                    let genshin = try JSON(data: data.data(using: .utf8)!)
//                    let role = genshin["data"]["list"].arrayValue.filter({$0["game_biz"].stringValue == "hk4e_cn"}).first
//                    if let role = role {
//                        let jsonResult = try JSONSerialization.data(withJSONObject: [
//                            "genshinServer": role["region"].stringValue,
//                            "genshinName": role["region_name"].stringValue,
//                            "genshinUid": role["game_uid"].stringValue
//                        ])
//                        return EventMessager(evtState: true, data: jsonResult)
//                    } else {
//                        return EventMessager(evtState: false, data: "没有找到你绑定的原神账号！")
//                    }
//                } catch {
//                    return EventMessager(evtState: false, data: error.localizedDescription)
//                }
//            } else {
//                return EventMessager(evtState: false, data: "服务器返回数据异常，请检查网络或重新登录。")
//            }
//        } else {
//            return result
//        }
    }
}
