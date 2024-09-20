//
//  AccountModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/16.
//

import Foundation
import CoreData
import AppKit
import CoreImage.CIFilterBuiltins
import SwiftyJSON

class AccountModel: ObservableObject {
    var dm: NSManagedObjectContext?
    @Published var signedAccount: [ShequAccount] = []
    @Published var qrCode: NSImage = NSImage()
    @Published var qrLogin = QrLoginInfo()
    @Published var showCookieLogin = false
    
    func initSomething(dataManager: NSManagedObjectContext){
        dm = dataManager
        fetchUsers()
    }
    
    func fetchUsers() {
        do {
            signedAccount.removeAll()
            signedAccount = try dm!.fetch(ShequAccount.fetchRequest())
        } catch {
            uploadAnError(fatalInfo: error)
            GlobalUIModel.exported.makeAnAlert(
                type: 3,
                msg: String.localizedStringWithFormat(
                    NSLocalizedString("account.error.fetch_users", comment: ""), error.localizedDescription)
            )
        }
    }
    
    /// 创建一个二维码并显示
    func fetchQrCode(isRefresh: Bool = false) async {
        do {
            let qrUrl = try await AccountService.shared.fetchQRCode()
            DispatchQueue.main.async {
                self.dealImg(pic: qrUrl)
                self.qrLogin.qrLink = qrUrl
                self.qrLogin.showIt = true
            }
        } catch {
            uploadAnError(fatalInfo: error)
            DispatchQueue.main.async {
                if isRefresh {
                    self.cancelLoginByQr()
                }
                GlobalUIModel.exported.makeAnAlert(
                    type: 3,
                    msg: String.localizedStringWithFormat(
                        NSLocalizedString("account.error.fetch_qr", comment: ""), error.localizedDescription)
                )
            }
        }
    }
    
    /// 轮询二维码状态并尝试登录
    func queryQrCode() async {
        let comps = URLComponents(string: qrLogin.qrLink)
        do {
            if let ticket = comps?.queryItems?.filter({$0.name == "ticket"}).first { //智能获取ticket
                let result = try await JSON(data: AccountService.shared.queryCodeState(ticket: ticket.value!))
                let sameCount = self.signedAccount.filter({$0.stuid! == result["uid"].stringValue}).count
                if sameCount == 0 {
                    // 已经拿到了水社id和game_token（似乎是长期的），记得入库。
                    let gameToken = result["game_token"].stringValue
                    // 获取stoken，顺带获取到mid -> Data can be formed to JSON
                    let stoken = try await JSON(data: AccountService.shared.pullUserSToken(uid: result["uid"].stringValue, token: gameToken))
                    // 获取cookie_token -> String
                    let cookieToken = try await AccountService.shared.pullUserCookieToken(uid: result["uid"].stringValue, token: gameToken)
                    // 获取米社账号头像和昵称 -> Data can be formed to JSON
                    let sheBasic = try await JSON(data: AccountService.shared.pullUserSheInfo(uid: result["uid"].stringValue))
                    // 获取原神账号基本和区服信息 -> Data can be formed to JSON
                    let hk4e = try await JSON(data: AccountService.shared.pullHk4eBasic(uid: result["uid"].stringValue, stoken: stoken["stoken"].stringValue, mid: stoken["mid"].stringValue))
                    // 获取Ltoken -> String
                    let ltoken = try await AccountService.shared.pullUserLtoken(uid: result["uid"].stringValue, stoken: stoken["stoken"].stringValue, mid: stoken["mid"].stringValue)
                    // 获取角色橱窗信息和原神游戏头像等信息（橱窗信息会存储到文件系统）
                    let other = try await AccountService.shared.pullAndPutGameInfo(uid: hk4e["genshinUid"].stringValue)
                    DispatchQueue.main.async {
                        self.writeAccount(
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
                            stuid: result["uid"].stringValue,
                            genshinPicId: other
                        )
                        GlobalUIModel.exported.makeAnAlert(type: 1, msg: NSLocalizedString("account.login_ok", comment: ""))
                        self.cancelLoginByQr()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.cancelLoginByQr()
                        GlobalUIModel.exported.makeAnAlert(
                            type: 3,
                            msg: NSLocalizedString("account.error.same_account", comment: "")
                        )
                    }
                }
            }
        } catch {
            uploadAnError(fatalInfo: error)
            DispatchQueue.main.async {
                self.cancelLoginByQr()
                GlobalUIModel.exported.makeAnAlert(
                    type: 3,
                    msg: String.localizedStringWithFormat(
                        NSLocalizedString("account.login_no", comment: ""),
                        error.localizedDescription
                    )
                )
            }
        }
    }
    
    func cancelLoginByQr() {
        qrLogin.showIt = false; qrLogin.qrLink = ""
        qrCode = NSImage()
    }
    
    /// 检查cookie的内容 并进行后续的操作
    func checkCookieContent(cookieInput: String, clean: @escaping () -> Void) async {
        let cookieGroup = cookieInput.split(separator: ";")
        let stuid = cookieGroup.filter({$0.starts(with: "stuid")}).first?.split(separator: "=")[1]
        let stoken = cookieGroup.filter({$0.starts(with: "stoken")}).first?.split(separator: "=")[1]
        let mid = cookieGroup.filter({$0.starts(with: "mid")}).first?.split(separator: "=")[1]
        if stuid != nil && stoken != nil && mid != nil {
            do {
                let sameCount = self.signedAccount.filter({$0.stuid! == String(stuid!)}).count
                if sameCount == 0 {
                    let cookieToken = try await AccountService.shared.pullUserCookieToken(uid: String(stuid!), stoken: String(stoken!), mid: String(mid!))
                    let gameToken = try await AccountService.shared.pullUserGameToken(stoken: String(stoken!), mid: String(mid!))
                    let sheBasic = try await JSON(data: AccountService.shared.pullUserSheInfo(uid: String(stuid!)))
                    let hk4e = try await JSON(data: AccountService.shared.pullHk4eBasic(uid: String(stuid!), stoken: "\(String(stoken!))==.CAE=", mid: String(mid!)))
                    let ltoken = try await AccountService.shared.pullUserLtoken(uid: String(stuid!), stoken: "\(String(stoken!))==.CAE=", mid: String(mid!))
                    let other = try await AccountService.shared.pullAndPutGameInfo(uid: hk4e["genshinUid"].stringValue)
                    DispatchQueue.main.async {
                        self.writeAccount(
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
                            genshinPicId: other
                        )
                        clean()
                        GlobalUIModel.exported.makeAnAlert(type: 1, msg: NSLocalizedString("account.login_ok", comment: ""))
                    }
                } else {
                    DispatchQueue.main.async {
                        clean()
                        GlobalUIModel.exported.makeAnAlert(
                            type: 3,
                            msg: NSLocalizedString("account.error.same_account", comment: "")
                        )
                    }
                }
            } catch {
                uploadAnError(fatalInfo: error)
                DispatchQueue.main.async {
                    clean()
                    GlobalUIModel.exported.makeAnAlert(
                        type: 3,
                        msg: String.localizedStringWithFormat(
                            NSLocalizedString("account.login_no", comment: ""),
                            error.localizedDescription
                        )
                    )
                }
            }
        }
    }
    
    private func dealImg(pic: String) {
        qrCode = NSImage()
        let context = CIContext()
        let generator = CIFilter.qrCodeGenerator()
        generator.message = pic.data(using: .utf8)!
        guard
            let output = generator.outputImage,
            let ci = context.createCGImage(output, from: output.extent)
        else { return }
        qrCode = NSImage(cgImage: ci, size: NSSize(width: 250, height: 250))
    }
    
    /// 二维码登录弹窗的一些信息
    struct QrLoginInfo {
        var showIt: Bool = false
        /// 二维码所代表的链接
        var qrLink: String
        
        init(showIt: Bool = false, qrLink: String = "") {
            self.showIt = showIt
            self.qrLink = qrLink
        }
    }
    
    private func writeAccount(
        cookieToken: String, gameToken: String, genshinServer: String, genshinServerName: String, genshinUID: String,
        genshinNicname: String, level: String, ltoken: String, mid: String, misheHead: String, misheNicname: String,
        stoken: String, stuid: String, genshinPicId: String
    ) {
        let newData = ShequAccount(context: dm!)
        if signedAccount.count == 0 { // 如果没有账号则自动将刚添加的用作默认
            newData.active = true
            UserDefaultHelper.shared.setValue(forKey: "defaultAccount", value: genshinUID)
        }
        newData.cookieToken = cookieToken
        newData.gameToken = gameToken
        newData.serverRegion = genshinServer //cn_gf01
        newData.serverName = genshinServerName //天空岛
        newData.genshinUID = genshinUID
        newData.genshinNicname = genshinNicname
        newData.level = level
        newData.ltoken = ltoken
        newData.mid = mid
        newData.shequHead = misheHead
        newData.shequNicname = misheNicname
        newData.stoken = stoken
        newData.stuid = stuid
        newData.genshinPicID = genshinPicId
        let _ = CoreDataHelper.shared.save()
        signedAccount.removeAll()
        signedAccount = try! dm!.fetch(ShequAccount.fetchRequest())
    }
}
