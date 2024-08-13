//
//  Character+Verification.swift
//  TravellersBag
//  这个类是用于获取用户角色信息的单例类，但也包含了人机验证的共享顶层函数
//  Created by 鸳汐 on 2024/8/13.
//

import Foundation

/// 角色信息服务类
class CharacterService {
    static let shared = CharacterService()
    
    func testCode(user: HoyoAccounts) async {
        do {
            let result = try await createVerificationCode(user: user)
            print(result.rawString()!)
        } catch {
            print(error.localizedDescription)
        }
    }
}

/// # 下面的代码用于尝试解决 api-takumi-record.mihoyo.com 域名下部分api的风控问题
// 值得注意的是，即使这么做依然会出现返回10306等错误。

/// 生成极验验证码
func createVerificationCode(user: HoyoAccounts) async throws -> JSON {
    var req = URLRequest(url: URL(string: ApiEndpoints.shared.getGeetestRequired())!)
    req.setHost(host: "api-takumi-record.mihoyo.com")
    req.setValue(
        "stuid=\(user.stuid!);stoken=\(user.stoken!);ltuid=\(user.stuid!);ltoken=\(user.ltoken!);mid=\(user.mid!)", 
        forHTTPHeaderField: "Cookie"
    )
    req.setValue("zh-cn", forHTTPHeaderField: "x-rpc-language")
    req.setUA()
    req.setDS(version: SaltVersion.V2, type: SaltType.X4, q: "is_high=true", include: false)
    req.setReferer(referer: "https://webstatic.mihoyo.com")
    req.setValue("v4.1.5-ys_#/ys/daily", forHTTPHeaderField: "x-rpc-page")
    req.setValue("https://webstatic.mihoyo.com", forHTTPHeaderField: "Origin")
    req.setXRPCAppInfo(client: "5")
    req.setDeviceInfoHeaders()
    req.setValue("2", forHTTPHeaderField: "x-rpc-challenge_game")
    req.setValue("https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/character", forHTTPHeaderField: "x-rpc-challenge_path")
    return try await req.receiveOrThrow()
}

/// 向水社服务器验证极验的返回代码
func tryGeetestCode(user: HoyoAccounts, validate: String, challenge: String) async throws -> JSON {
    var req = URLRequest(url: URL(string: ApiEndpoints.shared.getGeetestResult())!)
    req.setHost(host: "api-takumi-record.mihoyo.com")
    req.setValue(
        "stuid=\(user.stuid!);stoken=\(user.stoken!);ltuid=\(user.stuid!);ltoken=\(user.ltoken!);mid=\(user.mid!)",
        forHTTPHeaderField: "Cookie"
    )
    req.setValue("zh-cn", forHTTPHeaderField: "x-rpc-language")
    req.setUA()
    req.setDS(version: SaltVersion.V2, type: SaltType.X4, include: false)
    req.setReferer(referer: "https://webstatic.mihoyo.com")
    req.setValue("v4.1.5-ys_#/ys/daily", forHTTPHeaderField: "x-rpc-page")
    req.setValue("https://webstatic.mihoyo.com", forHTTPHeaderField: "Origin")
    req.setXRPCAppInfo(client: "5")
    req.setDeviceInfoHeaders()
    req.setValue("2", forHTTPHeaderField: "x-rpc-challenge_game")
    req.setValue("https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/character", forHTTPHeaderField: "x-rpc-challenge_path")
    return try await req.receiveOrThrow(isPost: true, reqBody: JSONSerialization.data(withJSONObject: [
        "geetest_validate": validate, "geetest_challenge": challenge, "geetest_seccode": "\(validate)|jordan"
    ]))
}
