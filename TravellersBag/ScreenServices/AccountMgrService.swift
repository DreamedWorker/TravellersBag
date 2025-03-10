//
//  AccountMgrService.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/3/8.
//

import Foundation
import AppKit
import CoreImage.CIFilterBuiltins
import SwiftyJSON

class AccountMgrService: ObservableObject, @unchecked Sendable {
    @Published var alertMate = AlertMate()
    @Published var loginQRCode: NSImage? = nil
    @Published var picURL: String = ""
    
// MARK: - 状态的 UI 功能
    func queryStatusAndLogin(
        hasSame: (String) -> Bool,
        counts: Int,
        dismiss: @escaping () -> Void
    ) async -> MihoyoAccount? {
        let comps = URLComponents(string: picURL)
        do {
            if let ticket = comps?.queryItems?.filter({$0.name == "ticket"}).first {
                let queryedData = await queryCodeState(ticket: ticket.value!)
                if !queryedData.isEmpty {
                    let queryResult = try! JSON(data: queryedData)
                    if hasSame(queryResult["uid"].stringValue) {
                        alertMate.showAlert(msg: NSLocalizedString("account.error.same", comment: ""))
                        return nil
                    } else {
                        // 已经拿到了水社id和game_token（似乎是长期的），记得入库。
                        let gameToken = queryResult["game_token"].stringValue
                        // 获取stoken，顺带获取到mid -> Data can be formed to JSON
                        let stoken = try await JSON(data: pullUserSToken(uid: queryResult["uid"].stringValue, token: gameToken))
                        // 获取cookie_token -> String
                        let cookieToken = try await pullUserCookieToken(uid: queryResult["uid"].stringValue, token: gameToken)
                        // 获取米社账号头像和昵称 -> Data can be formed to JSON
                        let sheBasic = try await JSON(data: pullUserSheInfo(uid: queryResult["uid"].stringValue))
                        // 获取原神账号基本和区服信息 -> Data can be formed to JSON
                        let hk4e = try await JSON(data: pullHk4eBasic(uid: queryResult["uid"].stringValue, stoken: stoken["stoken"].stringValue, mid: stoken["mid"].stringValue))
                        // 获取Ltoken -> String
                        let ltoken = try await pullUserLtoken(uid: queryResult["uid"].stringValue, stoken: stoken["stoken"].stringValue, mid: stoken["mid"].stringValue)
                        return writeAccount(
                            cookieToken: cookieToken,
                            gameToken: gameToken,
                            genshinServer: hk4e["region"].stringValue,
                            genshinServerName: hk4e["genshinName"].stringValue,
                            genshinUID: hk4e["genshinUid"].stringValue,
                            genshinNicname: hk4e["genshinNicname"].stringValue,
                            level: hk4e["level"].stringValue,
                            ltoken: ltoken,
                            mid: stoken["mid"].stringValue,
                            misheHead: sheBasic["avatar_url"].stringValue,
                            misheNicname: sheBasic["nickname"].stringValue,
                            stoken: stoken["stoken"].stringValue,
                            stuid: queryResult["uid"].stringValue,
                            genshinPicId: "other",
                            counts: counts
                        )
                    }
                } else {
                    DispatchQueue.main.async { [self] in
                        dismiss()
                        alertMate.showAlert(msg: NSLocalizedString("account.error.same", comment: ""))
                    }
                    return nil
                }
            } else {
                DispatchQueue.main.async { [self] in
                    dismiss()
                    alertMate.showAlert(msg: NSLocalizedString("account.error.emptyFromServer", comment: ""))
                }
                return nil
            }
        } catch {
            DispatchQueue.main.async { [self] in
                dismiss()
                alertMate.showAlert(msg: NSLocalizedString("account.error.emptyFromQr", comment: ""))
            }
            return nil
        }
    }
    
    /// 检查账号的可访问性 只有设备指纹正常本函数才会执行
    func checkAccountState(account: MihoyoAccount) async -> MihoyoAccount? {
        do {
            let _ = try await pullUserLtoken(uid: account.cookies.stuid, stoken: account.cookies.stoken, mid: account.cookies.mid)
            DispatchQueue.main.async {
                self.alertMate.showAlert(msg: NSLocalizedString("account.tip.noUpdate", comment: ""))
            }
            return nil
        } catch {
            // STOKEN 已经过期
            let gameToken = account.cookies.gameToken; let uid = account.cookies.stuid
            do {
                // 获取stoken，顺带获取到mid -> Data can be formed to JSON
                let stoken = try await JSON(data: pullUserSToken(uid: uid, token: gameToken))
                // 获取cookie_token -> String
                let cookieToken = try await pullUserCookieToken(uid: uid, token: gameToken)
                // 获取Ltoken -> String
                let ltoken = try await pullUserLtoken(uid: uid, stoken: stoken["stoken"].stringValue, mid: stoken["mid"].stringValue)
                let neoAccount = account
                neoAccount.cookies.stoken = stoken["stoken"].stringValue
                neoAccount.cookies.cookieToken = cookieToken
                neoAccount.cookies.ltoken = ltoken
                alertMate.showAlert(msg: NSLocalizedString("account.tip.updated", comment: ""))
                return neoAccount
            } catch {
                alertMate.showAlert(msg: NSLocalizedString("account.error.update", comment: ""))
                return nil
            }
        }
    }
    
    private func writeAccount(
        cookieToken: String, gameToken: String, genshinServer: String, genshinServerName: String, genshinUID: String,
        genshinNicname: String, level: String, ltoken: String, mid: String, misheHead: String, misheNicname: String,
        stoken: String, stuid: String, genshinPicId: String, counts: Int
    ) -> MihoyoAccount {
        let cookies = MihoyoAccount.AccountCookie(cookieToken: cookieToken, gameToken: gameToken, ltoken: ltoken, mid: mid, stoken: stoken, stuid: stuid)
        let game = MihoyoAccount.AccountGameBreif(genshinNicname: genshinNicname, genshinPicID: genshinPicId, genshinUID: genshinUID, level: level, serverName: genshinServerName, serverRegion: genshinServer)
        let newData = MihoyoAccount(
            active: (counts == 0) ? true : false, stuidForTest: stuid, cookies: cookies, gameInfo: game,
            misheHead: misheHead, misheNicname: misheNicname
        )
        return newData
    }
    
    // MARK: - 非状态的 UI 功能
    /// 获取一个二维码链接。
    func fetchQRCode() async throws -> String {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getFetchQRCode())!)
        let result = try await req.receiveOrThrow(
            isPost: true,
            reqBody: try! JSONSerialization.data(
                withJSONObject: ["app_id": "2", "device": PreferenceMgr.default.getValue(key: TBData.DEVICE_ID, def: "")]
            ))
        return result["url"].stringValue
    }
    
    /// 为链接创建二维码
    func generateQRCode(from string: String) -> NSImage? {
        let data = string.data(using: .ascii)
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.correctionLevel = "H"
        guard let outputImage = filter.outputImage else { return nil }
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: .init(width: 98, height: 98))
    }
    
    /// 查询指定ticket的二维码扫描状态。如果成功则返回一个可转为json的Data数据，包含社区ID和游戏Token
    func queryCodeState(ticket: String) async -> Data {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getQueryQRState())!)
        let result = try! await JSON(data: req.receiveOrBlackData(
            isPost: true,
            reqBody: try! JSONSerialization.data(
                withJSONObject: ["app_id": "2", "device": PreferenceMgr.default.getValue(key: TBData.DEVICE_ID, def: ""), "ticket": ticket]
            )
        ))
        if result.contains(where: { $0.0 == "ProgramError" }) {
            return Data.empty
        } else if result["stat"].stringValue != "Confirmed" {
            return Data.empty
        } else {
            let futherData = try! JSON(data: result["payload"]["raw"].stringValue.data(using: .utf8)!)
            return try! JSONSerialization.data(withJSONObject: [
                "uid": futherData["uid"].stringValue, "game_token": futherData["token"].stringValue
            ])
        }
    }
    
    /// 通过GameToken获取SToken
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
    
    /// 通过Stoken获取CookieToken
    func pullUserCookieToken(uid: String, stoken: String, mid: String) async throws -> String {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getCookieTokenByStoken())!)
        req.setValue("stoken=\(stoken)==.CAE=;mid=\(mid)", forHTTPHeaderField: "Cookie")
        // 写的时候没有注意到split方法把token的尾部给干掉了，难怪之前一直调不通
        req.setDS(version: .V2, type: .PROD)
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
    
    /// 获取用户的Ltoken
    func pullUserLtoken(uid: String, stoken: String, mid: String) async throws -> String {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getLTokenBySToken())!)
        req.setUser(uid: uid, stoken: stoken, mid: mid)
        let result = try await req.receiveOrThrow()
        return result["ltoken"].stringValue
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
        req.setDS(version: .V1, type: .K2)
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
                NSLocalizedDescriptionKey: NSLocalizedString("account.error.cannot_copy_hk4e_detail", comment: "")
            ])
        }
    }
}
