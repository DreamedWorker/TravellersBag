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
    
    /// 获取一个二维码链接 信使的data全部可以转为String。
    func fetchQRCode() async -> EventMessager {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getFetchQRCode())!)
        let result = await req.receiveData(
            session: httpSession(),
            isPost: true,
            reqBody: try! JSONSerialization.data(
                withJSONObject: ["app_id": "2", "device": envKV.string(forKey: LocalEnvironment.DEVICE_ID)!]
            )) // 使用原神的ID请求到的二维码因为技术原因在扫描后会报安全错误，故采用此。
        if result.evtState {
            do {
                let json = try JSON(data: (result.data as! String).data(using: .utf8)!)
                if json["retcode"].intValue == 0 {
                    return EventMessager(evtState: true, data: json["data"]["url"].stringValue)
                } else {
                    return EventMessager(evtState: false, data: "参数错误，未能获得到二维码URL。")
                }
            } catch {
                return EventMessager(evtState: false, data: error.localizedDescription)
            }
        } else {
            return result
        }
    }
    
    /// 查询指定ticket的二维码扫描状态
    func queryCodeState(ticket: String) async -> EventMessager {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getQueryQRState())!)
        let result = await req.receiveData(
            session: httpSession(),
            isPost: true,
            reqBody: try! JSONSerialization.data(
                withJSONObject: ["app_id": "2", "device": envKV.string(forKey: LocalEnvironment.DEVICE_ID)!, "ticket": ticket]
            ))
        if result.evtState {
            let data = result.data as! String
            if data.contains("Confirmed") {
                return EventMessager(evtState: true, data: data)
            } else {
                return EventMessager(evtState: false, data: "未扫码或已过期。")
            }
        } else {
            return EventMessager(evtState: false, data: "网络请求失败。")
        }
    }
    
    /// 通过GameToken获取SToken
    /// - Returns:
    ///   - EventMessager: 如果成功，返回一个可转为HoyoUser结构体的值，否则返回错误信息字符串
    func pullUserSToken(gameTokenData: String) async -> EventMessager {
        do {
            let json = try JSON(data: gameTokenData.data(using: .utf8)!) // 吐槽一下下面两行 一段json埋这么深干嘛
            let innerJSON = try JSON(data: json["data"]["payload"]["raw"].stringValue.data(using: .utf8)!)
            let sheID = innerJSON["uid"].stringValue
            let gameToken = innerJSON["token"].stringValue
            var req = URLRequest(url: URL(string: ApiEndpoints.shared.getSTokenByGameToken())!)
            req.setValue("bll8iq97cem8", forHTTPHeaderField: "x-rpc-app_id")
            let result = await req.receiveData(
                session: httpSession(),
                isPost: true,
                reqBody: try! JSONSerialization.data(withJSONObject: ["account_id": Int(sheID)!, "game_token": gameToken]))
            if result.evtState {
                let data = result.data as! String
                if data.contains("OK") {
                    // 先拿到数据 关于头像和绑定的原神数据什么的 之后再通过判断对应参数是否为空来获取
                    let tokenJSON = try JSON(data: data.data(using: .utf8)!)
                    let stoken = tokenJSON["data"]["token"]["token"].stringValue
                    let stuid = tokenJSON["data"]["user_info"]["aid"].stringValue // aid实际上就是stuid 就是米社id
                    let mid = tokenJSON["data"]["user_info"]["mid"].stringValue
                    return EventMessager(evtState: true, data: HoyoUser(stuid: stuid, stoken: stoken, mid: mid))
                } else {
                    return EventMessager(evtState: false, data: data)
                }
            } else {
                return EventMessager(evtState: false, data: "pullUserSToken:\(result.data as! String)")
            }
        } catch {
            return EventMessager(evtState: false, data: "pullUserSToken:\(error.localizedDescription)")
        }
    }
    
    /// 获取用户的Ltoken
    func pullUserLtoken(user: HoyoAccounts) async -> EventMessager {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getLTokenBySToken())!)
        req.setUser(singleUser: user)
        let result = await req.receiveData(session: httpSession(), reqBody: nil)
        if result.evtState {
            let data = result.data as! String
            if data.contains("OK") {
                do {
                    let json = try JSON(data: data.data(using: .utf8)!)
                    return EventMessager(evtState: true, data: json["data"]["ltoken"].stringValue)
                } catch {
                    return EventMessager(evtState: false, data: error.localizedDescription)
                }
            } else {
                return EventMessager(evtState: false, data: "服务器返回数据异常，请重新登录或检查网络。")
            }
        } else {
            return result
        }
    }
    
    /// 获取用户的水社昵称和头像 成功则返回一个json的Data
    func pullUserSheInfo(uid: String) async -> EventMessager {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getSheUserInfo(uid: uid))!)
        let result = await req.receiveData(session: httpSession(), reqBody: nil)
        if result.evtState {
            let data = result.data as! String
            if data.contains("OK") || !data.contains("20001") {
                do {
                    let json = try JSON(data: data.data(using: .utf8)!)
                    let userInfo = json["data"]["user_info"]
                    let result = try JSONSerialization.data(withJSONObject: [
                        "nickname": userInfo["nickname"].stringValue,
                        "avatar_url": userInfo["avatar_url"].stringValue
                    ])
                    return EventMessager(evtState: true, data: result)
                } catch {
                    return EventMessager(evtState: false, data: error.localizedDescription)
                }
            } else {
                return EventMessager(evtState: false, data: "服务器返回数据异常")
            }
        } else {
            return result
        }
    }
    
    /// 获取用户原神的基本数据 成功则返回一个包含服务器、服务器名称、原神uid的jsonData
    func pullHk4eBasic(user: HoyoAccounts) async -> EventMessager {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getGameBasic())!)
        req.setHost(host: "api-takumi.miyoushe.com")
        req.setReferer(referer: "https://app.mihoyo.com")
        req.setValue("https://api-takumi.miyoushe.com", forHTTPHeaderField: "Origin")
        req.setUA()
        req.setDS(version: SaltVersion.V1, type: SaltType.K2)
        req.setDeviceInfoHeaders()
        req.setUser(singleUser: user)
        req.setXRPCAppInfo()
        req.setXRequestWith()
        let result = await req.receiveData(session: httpSession(), reqBody: nil)
        if result.evtState {
            let data = result.data as! String
            if data.contains("OK") {
                do {
                    let genshin = try JSON(data: data.data(using: .utf8)!)
                    let role = genshin["data"]["list"].arrayValue.filter({$0["game_biz"].stringValue == "hk4e_cn"}).first
                    if let role = role {
                        let jsonResult = try JSONSerialization.data(withJSONObject: [
                            "genshinServer": role["region"].stringValue,
                            "genshinName": role["region_name"].stringValue,
                            "genshinUid": role["game_uid"].stringValue
                        ])
                        return EventMessager(evtState: true, data: jsonResult)
                    } else {
                        return EventMessager(evtState: false, data: "没有找到你绑定的原神账号！")
                    }
                } catch {
                    return EventMessager(evtState: false, data: error.localizedDescription)
                }
            } else {
                return EventMessager(evtState: false, data: "服务器返回数据异常，请检查网络或重新登录。")
            }
        } else {
            return result
        }
    }
}
