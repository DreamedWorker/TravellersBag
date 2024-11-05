//
//  AccountModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/1.
//

import Foundation
import SwiftData
import CoreImage
import AppKit
import SwiftyJSON

class AccountViewModel: ObservableObject {
    @Published var accounts: [MihoyoAccount] = []
    @Published var alertMate = AlertMate()
    @Published var showAddType: Bool = false
    @Published var loginByQr: Bool = false
    @Published var loginQRCode: NSImage? = nil
    
    private var picURL: String = ""
    
    @MainActor func getLocalAccounts() {
        accounts.removeAll()
        let storedAccounts = FetchDescriptor<MihoyoAccount>()
        do {
            accounts = try tbDatabase.mainContext.fetch(storedAccounts)
        } catch {
            alertMate.showAlert(
                msg: String.localizedStringWithFormat(
                    NSLocalizedString("account.error.queryAccounts", comment: ""), error.localizedDescription)
            )
        }
    }
    
    func getQrAndShowWindow() async {
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
    
    func queryStatusAndLogin() async {
        let comps = URLComponents(string: picURL)
        if let ticket = comps?.queryItems?.filter({$0.name == "ticket"}).first {
            do {
                let queryResult = try await JSON(data: TBAccountService.queryCodeState(ticket: ticket.value!))
                let sameCount = self.accounts.filter({$0.stuidForTest == queryResult["uid"].stringValue}).count
                if sameCount > 0 {
                    DispatchQueue.main.async { [self] in
                        getLocalAccounts()
                        loginByQr = false; loginQRCode = nil
                        alertMate.showAlert(msg: NSLocalizedString("account.error.same", comment: ""))
                    }
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
                    try await writeAccount(
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
                        genshinPicId: "other"
                    )
                    DispatchQueue.main.async { [self] in
                        getLocalAccounts()
                        loginByQr = false; loginQRCode = nil
                        alertMate.showAlert(msg: NSLocalizedString("account.login.ok", comment: ""))
                    }
                }
            } catch {
                DispatchQueue.main.async { [self] in
                    getLocalAccounts()
                    loginByQr = false; loginQRCode = nil
                    alertMate.showAlert(msg: String.localizedStringWithFormat(
                        NSLocalizedString("account.login.no", comment: ""), error.localizedDescription)
                    )
                }
            }
        }
    }
    
    @MainActor func setDefault(account: MihoyoAccount) {
        if account.active {
            alertMate.showAlert(msg: NSLocalizedString("account.error.setDef", comment: ""))
        } else {
            //只需要提取第一个，因为只能存在一个默认账号
            if let defAccount = getDefaultAccount() {
                defAccount.active = false
                account.active = true
                try! tbDatabase.mainContext.save()
                alertMate.showAlert(msg: NSLocalizedString("account.info.setAsDef", comment: ""))
            } else {
                alertMate.showAlert(msg: NSLocalizedString("account.error.localEnv", comment: ""))
            }
        }
    }
    
    @MainActor func logoutFunc(account: MihoyoAccount) {
        let isDef = account.active
        tbDatabase.mainContext.delete(account)
        try! tbDatabase.mainContext.save()
        getLocalAccounts()
        if accounts.count == 0 {
            NSApplication.shared.terminate(self)
        } else {
            if isDef {
                let neoDef = accounts.first!
                neoDef.active = true
                try! tbDatabase.mainContext.save()
                alertMate.showAlert(msg: NSLocalizedString("account.info.reDef", comment: ""))
            }
        }
    }
    
    func checkAccountState(account: MihoyoAccount) async {
        do {
            let _ = try await TBAccountService.pullUserLtoken(uid: account.cookies.stuid, stoken: account.cookies.stoken, mid: account.cookies.mid)
            makeAToastInIOThread(msg: NSLocalizedString("account.info.noUpdate", comment: ""))
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
                DispatchQueue.main.async {
                    let neoAccount = account
                    neoAccount.cookies.stoken = stoken["stoken"].stringValue
                    neoAccount.cookies.cookieToken = cookieToken
                    neoAccount.cookies.ltoken = ltoken
                    try! tbDatabase.mainContext.save()
                    self.getLocalAccounts()
                }
                makeAToastInIOThread(msg: NSLocalizedString("account.info.updated", comment: ""))
            } catch {
                makeAToastInIOThread(msg: NSLocalizedString("account.error.update", comment: ""))
            }
        }
    }
    
    @MainActor private func writeAccount(
        cookieToken: String, gameToken: String, genshinServer: String, genshinServerName: String, genshinUID: String,
        genshinNicname: String, level: String, ltoken: String, mid: String, misheHead: String, misheNicname: String,
        stoken: String, stuid: String, genshinPicId: String
    ) throws {
        let cookies = AccountCookie(cookieToken: cookieToken, gameToken: gameToken, ltoken: ltoken, mid: mid, stoken: stoken, stuid: stuid)
        let game = AccountGameBreif(genshinNicname: genshinNicname, genshinPicID: genshinPicId, genshinUID: genshinUID, level: level, serverName: genshinServerName, serverRegion: genshinServer)
        let newData = MihoyoAccount(
            active: (accounts.count == 0) ? true : false, stuidForTest: stuid, cookies: cookies, gameInfo: game,
            misheHead: misheHead, misheNicname: misheNicname
        )
        tbDatabase.mainContext.insert(newData)
        try tbDatabase.mainContext.save()
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
    
    private func makeAToastInIOThread(msg: String) {
        DispatchQueue.main.async {
            self.alertMate.showAlert(msg: msg)
        }
    }
}
