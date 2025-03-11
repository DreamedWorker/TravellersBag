//
//  AccountMgrModel.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/3/11.
//

import Foundation
import AppKit
import SwiftyJSON

class AccountMgrModel: ObservableObject, @unchecked Sendable {
    @Published var alertMate = AlertMate()
    @Published var loginQRCode: NSImage? = nil
    @Published var picURL: String = ""
    
    private let service = AccountMgrService()
    
    /// Get the url of the QRCode
    func fetchQRCode() async throws -> String {
        try await service.fetchQRCode()
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
    
    /// 查询二维码的扫描状态并尝试登录
    func queryStatusAndLogin(
        hasSame: (String) -> Bool,
        counts: Int,
        dismiss: @escaping () -> Void
    ) async -> MihoyoAccount? {
        let comps = URLComponents(string: picURL)
        do {
            if let ticket = comps?.queryItems?.filter({$0.name == "ticket"}).first {
                let queryedData = await service.queryCodeState(ticket: ticket.value!)
                if !queryedData.isEmpty {
                    let queryResult = try! JSON(data: queryedData)
                    if hasSame(queryResult["uid"].stringValue) {
                        alertMate.showAlert(msg: NSLocalizedString("account.error.same", comment: ""))
                        return nil
                    } else {
                        // 已经拿到了水社id和game_token（似乎是长期的），记得入库。
                        let gameToken = queryResult["game_token"].stringValue
                        // 获取stoken，顺带获取到mid -> Data can be formed to JSON
                        let stoken = try await JSON(data: service.pullUserSToken(uid: queryResult["uid"].stringValue, token: gameToken))
                        // 获取cookie_token -> String
                        let cookieToken = try await service.pullUserCookieToken(uid: queryResult["uid"].stringValue, token: gameToken)
                        // 获取米社账号头像和昵称 -> Data can be formed to JSON
                        let sheBasic = try await JSON(data: service.pullUserSheInfo(uid: queryResult["uid"].stringValue))
                        // 获取原神账号基本和区服信息 -> Data can be formed to JSON
                        let hk4e = try await JSON(data: service.pullHk4eBasic(uid: queryResult["uid"].stringValue, stoken: stoken["stoken"].stringValue, mid: stoken["mid"].stringValue))
                        // 获取Ltoken -> String
                        let ltoken = try await service.pullUserLtoken(uid: queryResult["uid"].stringValue, stoken: stoken["stoken"].stringValue, mid: stoken["mid"].stringValue)
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
                        alertMate.showAlert(msg: NSLocalizedString("account.error.qrState", comment: ""))
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
            let _ = try await service.pullUserLtoken(uid: account.cookies.stuid, stoken: account.cookies.stoken, mid: account.cookies.mid)
            DispatchQueue.main.async {
                self.alertMate.showAlert(msg: NSLocalizedString("account.tip.noUpdate", comment: ""))
            }
            return nil
        } catch {
            // STOKEN 已经过期
            let gameToken = account.cookies.gameToken; let uid = account.cookies.stuid
            do {
                // 获取stoken，顺带获取到mid -> Data can be formed to JSON
                let stoken = try await JSON(data: service.pullUserSToken(uid: uid, token: gameToken))
                // 获取cookie_token -> String
                let cookieToken = try await service.pullUserCookieToken(uid: uid, token: gameToken)
                // 获取Ltoken -> String
                let ltoken = try await service.pullUserLtoken(uid: uid, stoken: stoken["stoken"].stringValue, mid: stoken["mid"].stringValue)
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
}
