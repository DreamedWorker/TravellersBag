//
//  AccountViewModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/10.
//

import Foundation
import CoreImage
import AppKit
import SwiftyJSON

class AccountViewModel: ObservableObject {
    @Published var alertMate = AlertMate()
    @Published var loginByQr: Bool = false
    @Published var loginQRCode: NSImage? = nil
    @Published var loginByCookie: Bool = false
    @Published var loginCookie: String = ""
    
    private var picURL: String = ""
    
    @MainActor func getQrAndShowWindow() async {
        do {
            let url = try await TBAccountService.fetchQRCode()
            DispatchQueue.main.async {
                self.picURL = url
                self.generateQRCode(from: url)
            }
        } catch {
            DispatchQueue.main.async { [self] in
                loginQRCode = nil; loginByQr = false
                alertMate.showAlert(msg: String.localizedStringWithFormat(
                    NSLocalizedString("account.error.prepare", comment: ""), error.localizedDescription)
                )
            }
        }
    }
    
    @MainActor func queryStatusAndLogin(
        hasSame: (String) -> Bool,
        counts: Int
    ) async -> MihoyoAccount? {
        let comps = URLComponents(string: picURL)
        do {
            if let ticket = comps?.queryItems?.filter({$0.name == "ticket"}).first {
                let queryedData = await TBAccountService.queryCodeState(ticket: ticket.value!)
                if !queryedData.isEmpty {
                    let queryResult = try! JSON(data: queryedData)
                    if hasSame(queryResult["uid"].stringValue) {
                        alertMate.showAlert(msg: NSLocalizedString("account.error.same", comment: ""))
                        return nil
                    } else {
                        // 已经拿到了水社id和game_token（似乎是长期的），记得入库。
                        let gameToken = queryResult["game_token"].stringValue
                        // 获取stoken，顺带获取到mid -> Data can be formed to JSON
                        let stoken = try await JSON(data: TBAccountService.pullUserSToken(uid: queryResult["uid"].stringValue, token: gameToken))
                        // 获取cookie_token -> String
                        let cookieToken = try await TBAccountService.pullUserCookieToken(uid: queryResult["uid"].stringValue, token: gameToken)
                        // 获取米社账号头像和昵称 -> Data can be formed to JSON
                        let sheBasic = try await JSON(data: TBAccountService.pullUserSheInfo(uid: queryResult["uid"].stringValue))
                        // 获取原神账号基本和区服信息 -> Data can be formed to JSON
                        let hk4e = try await JSON(data: TBAccountService.pullHk4eBasic(uid: queryResult["uid"].stringValue, stoken: stoken["stoken"].stringValue, mid: stoken["mid"].stringValue))
                        // 获取Ltoken -> String
                        let ltoken = try await TBAccountService.pullUserLtoken(uid: queryResult["uid"].stringValue, stoken: stoken["stoken"].stringValue, mid: stoken["mid"].stringValue)
                        loginByQr = false; loginQRCode = nil
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
                    alertMate.showAlert(msg: NSLocalizedString("account.error.same", comment: ""))
                    loginByQr = false; loginQRCode = nil
                    return nil
                }
            } else {
                alertMate.showAlert(msg: NSLocalizedString("account.error.emptyFromServer", comment: ""))
                loginByQr = false; loginQRCode = nil
                return nil
            }
        } catch {
            alertMate.showAlert(msg: NSLocalizedString("account.error.emptyFromQr", comment: ""))
            loginByQr = false; loginQRCode = nil
            return nil
        }
    }
    
    @MainActor func loginByCookieFunc(
        hasSame: (String) -> Bool,
        counts: Int
    ) async -> MihoyoAccount? {
        let cookieGroup = loginCookie.split(separator: ";")
        let stuid = cookieGroup.filter({$0.starts(with: "stuid")}).first?.split(separator: "=")[1]
        let stoken = cookieGroup.filter({$0.starts(with: "stoken")}).first?.split(separator: "=")[1]
        let mid = cookieGroup.filter({$0.starts(with: "mid")}).first?.split(separator: "=")[1]
        if stuid != nil && stoken != nil && mid != nil {
            if hasSame(String(stuid!)) {
                alertMate.showAlert(msg: NSLocalizedString("account.error.same", comment: ""))
                loginByCookie = false; loginCookie = ""
                return nil
            } else {
                do {
                    let cookieToken = try await TBAccountService.pullUserCookieToken(uid: String(stuid!), stoken: String(stoken!), mid: String(mid!))
                    let gameToken = try await TBAccountService.pullUserGameToken(stoken: String(stoken!), mid: String(mid!))
                    let sheBasic = try await JSON(data: TBAccountService.pullUserSheInfo(uid: String(stuid!)))
                    let hk4e = try await JSON(data: TBAccountService.pullHk4eBasic(uid: String(stuid!), stoken: "\(String(stoken!))==.CAE=", mid: String(mid!)))
                    let ltoken = try await TBAccountService.pullUserLtoken(uid: String(stuid!), stoken: "\(String(stoken!))==.CAE=", mid: String(mid!))
                    loginByCookie = false; loginCookie = ""
                    return writeAccount(
                        cookieToken: cookieToken,
                        gameToken: gameToken,
                        genshinServer: hk4e["region"].stringValue,
                        genshinServerName: hk4e["genshinName"].stringValue,
                        genshinUID: hk4e["genshinUid"].stringValue,
                        genshinNicname: hk4e["genshinNicname"].stringValue,
                        level: hk4e["level"].stringValue,
                        ltoken: ltoken,
                        mid: String(mid!),
                        misheHead: sheBasic["avatar_url"].stringValue,
                        misheNicname: sheBasic["nickname"].stringValue,
                        stoken: "\(String(stoken!))==.CAE=",
                        stuid: String(stuid!),
                        genshinPicId: "other",
                        counts: counts
                    )
                } catch {
                    alertMate.showAlert(msg: NSLocalizedString("account.error.emptyFromServer", comment: ""))
                    loginByCookie = false; loginCookie = ""
                    return nil
                }
            }
        } else {
            alertMate.showAlert(msg: NSLocalizedString("account.error.incorrentCookie", comment: ""))
            loginByCookie = false; loginCookie = ""
            return nil
        }
    }
    
    @MainActor func checkAccountState(account: MihoyoAccount) async -> MihoyoAccount? {
        do {
            let _ = try await TBAccountService.pullUserLtoken(uid: account.cookies.stuid, stoken: account.cookies.stoken, mid: account.cookies.mid)
            alertMate.showAlert(msg: NSLocalizedString("account.info.noUpdate", comment: ""))
            return nil
        } catch {
            // STOKEN 已经过期
            let gameToken = account.cookies.gameToken; let uid = account.cookies.stuid
            do {
                // 获取stoken，顺带获取到mid -> Data can be formed to JSON
                let stoken = try await JSON(data: TBAccountService.pullUserSToken(uid: uid, token: gameToken))
                // 获取cookie_token -> String
                let cookieToken = try await TBAccountService.pullUserCookieToken(uid: uid, token: gameToken)
                // 获取Ltoken -> String
                let ltoken = try await TBAccountService.pullUserLtoken(uid: uid, stoken: stoken["stoken"].stringValue, mid: stoken["mid"].stringValue)
                let neoAccount = account
                neoAccount.cookies.stoken = stoken["stoken"].stringValue
                neoAccount.cookies.cookieToken = cookieToken
                neoAccount.cookies.ltoken = ltoken
                alertMate.showAlert(msg: NSLocalizedString("account.info.updated", comment: ""))
                return neoAccount
            } catch {
                alertMate.showAlert(msg: NSLocalizedString("account.error.update", comment: ""))
                return nil
            }
        }
    }
    
    func generateQRCode(from string: String) {
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(Data(string.utf8), forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")
        if let outputImage = filter?.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            let rep = NSCIImageRep(ciImage: scaledImage)
            let nsImage = NSImage(size: rep.size)
            nsImage.addRepresentation(rep)
            loginQRCode = nsImage; loginByQr = true
        } else {
            loginQRCode = nil; loginByQr = false
            alertMate.showAlert(msg: NSLocalizedString("account.error.createQR", comment: ""))
        }
    }
    
    private func writeAccount(
        cookieToken: String, gameToken: String, genshinServer: String, genshinServerName: String, genshinUID: String,
        genshinNicname: String, level: String, ltoken: String, mid: String, misheHead: String, misheNicname: String,
        stoken: String, stuid: String, genshinPicId: String, counts: Int
    ) -> MihoyoAccount {
        let cookies = AccountCookie(cookieToken: cookieToken, gameToken: gameToken, ltoken: ltoken, mid: mid, stoken: stoken, stuid: stuid)
        let game = AccountGameBreif(genshinNicname: genshinNicname, genshinPicID: genshinPicId, genshinUID: genshinUID, level: level, serverName: genshinServerName, serverRegion: genshinServer)
        let newData = MihoyoAccount(
            active: (counts == 0) ? true : false, stuidForTest: stuid, cookies: cookies, gameInfo: game,
            misheHead: misheHead, misheNicname: misheNicname
        )
        return newData
    }
}
