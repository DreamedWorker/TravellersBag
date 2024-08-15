//
//  AccountManagerModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/6.
//

import Foundation
import CoreData
import AppKit
import CoreImage.CIFilterBuiltins

class AccountManagerModel : ObservableObject {
    @Published var context: NSManagedObjectContext? = nil
    @Published var accountsHoyo: [HoyoAccounts] = [] // 水社账号列表
    @Published var showQRCodeWindow = false // 二维码登录弹窗
    @Published var showCookieWindow = false // cookie登录弹窗
    @Published var cookieInput = ""
    @Published var qrCodeImg: NSImage = NSImage()
    private var picURL: String = ""
    @Published var qrScanState = ""
    
    func fetchAccounts() {
        accountsHoyo.removeAll()
        do {
            let result = try context?.fetch(HoyoAccounts.fetchRequest())
            accountsHoyo = result ?? []
        } catch {
            ContentMessager.shared.showErrorDialog(msg: error.localizedDescription)
        }
    }
    
    /// 显示一张二维码
    func fetchQRCode() async {
        do {
            let result = try await AccountService.shared.fetchQRCode()
            DispatchQueue.main.async {
                self.picURL = result
                self.dealImg(pic: result)
            }
        } catch {
            DispatchQueue.main.async {
                self.qrScanState = error.localizedDescription
            }
        }
    }
    
    /// 查询二维码状态 并进行后续操作
    func queryQRState() async {
        let comps = URLComponents(string: picURL)
        do {
            if let ticket = comps?.queryItems?.filter({$0.name == "ticket"}).first { //智能获取ticket
                let result = try await JSON(data: AccountService.shared.queryCodeState(ticket: ticket.value!))
                let sameCount = self.accountsHoyo.filter({$0.stuid! == result["uid"].stringValue}).count
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
                    DispatchQueue.main.async { //写入账号到数据库
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
                            stuid: result["uid"].stringValue
                        )
                        self.cancelOp() // 此方法亦具有关闭窗口的效果
                    }
                    // 在这里尝试将原神账号的头像，角色橱窗的信息获取出来
                } else {
                    throw NSError(domain: "ui.login.with.qr", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: NSLocalizedString("account.service.repeated_acc", comment: "")
                    ])
                }
            } else {
                throw NSError(domain: "ui.login.with.qr", code: -2, userInfo: [
                    NSLocalizedDescriptionKey: NSLocalizedString("account.service.qr_no_token", comment: "")
                ])
            }
        } catch {
            DispatchQueue.main.async {
                self.qrScanState = error.localizedDescription
            }
        }
    }
    
    /// 检查cookie的内容 并进行后续的操作
    func checkCookieContent() async {
        let cookieGroup = self.cookieInput.split(separator: ";")
        let stuid = cookieGroup.filter({$0.starts(with: "stuid")}).first?.split(separator: "=")[1]
        let stoken = cookieGroup.filter({$0.starts(with: "stoken")}).first?.split(separator: "=")[1]
        let mid = cookieGroup.filter({$0.starts(with: "mid")}).first?.split(separator: "=")[1]
        if stuid != nil && stoken != nil && mid != nil {
            // 进行账号相同的判断
            do {
                let sameCount = self.accountsHoyo.filter({$0.stuid! == String(stuid!)}).count
                if sameCount == 0 {
                    let cookieToken = try await AccountService.shared.pullUserCookieToken(uid: String(stuid!), stoken: String(stoken!), mid: String(mid!))
                    let gameToken = try await AccountService.shared.pullUserGameToken(stoken: String(stoken!), mid: String(mid!))
                    let sheBasic = try await JSON(data: AccountService.shared.pullUserSheInfo(uid: String(stuid!)))
                    let hk4e = try await JSON(data: AccountService.shared.pullHk4eBasic(uid: String(stuid!), stoken: "\(String(stoken!))==.CAE=", mid: String(mid!)))
                    let ltoken = try await AccountService.shared.pullUserLtoken(uid: String(stuid!), stoken: "\(String(stoken!))==.CAE=", mid: String(mid!))
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
                            stuid: String(stuid!)
                        )
                        self.cookieInput = ""
                        self.showCookieWindow = false
                    }
                    // 在这里尝试将原神账号的头像，角色橱窗的信息获取出来
                } else {
                    throw NSError(domain: "ui.login.with.qr", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: NSLocalizedString("account.service.repeated_acc", comment: "")
                    ])
                }
            } catch {
                DispatchQueue.main.async {
                    self.qrScanState = error.localizedDescription
                }
            }
        } else {
            DispatchQueue.main.async {
                self.qrScanState = NSLocalizedString("account.cookie.type_error", comment: "")
            }
        }
    }
    
    func cancelOp() {
        qrCodeImg = NSImage()
        picURL = ""
        qrScanState = ""
    }
    
    /// 完善账号条目
//    func updateGameData(user: HoyoAccounts) async {
//    }
    
    private func dealImg(pic: String) {
        qrCodeImg = NSImage() // clear it
        let context = CIContext()
        let generator = CIFilter.qrCodeGenerator()
        generator.message = pic.data(using: .utf8)!
        guard
            let output = generator.outputImage,
            let ci = context.createCGImage(output, from: output.extent)
        else { return }
        qrCodeImg = NSImage(cgImage: ci, size: NSSize(width: 250, height: 250))
    }
    
    private func writeAccount(
        cookieToken: String, gameToken: String, genshinServer: String, genshinServerName: String, genshinUID: String,
        genshinNicname: String, level: String, ltoken: String, mid: String, misheHead: String, misheNicname: String,
        stoken: String, stuid: String
    ) {
        let newData = HoyoAccounts(context: context!)
        if accountsHoyo.count == 0 { // 如果没有账号则自动将刚添加的用作默认
            newData.activeAccount = true
            LocalEnvironment.shared.setStringValue(key: "default_account_stuid", value: stuid)
            LocalEnvironment.shared.setStringValue(key: "default_account_stoken", value: stoken)
            LocalEnvironment.shared.setStringValue(key: "default_account_mid", value: mid)
        }
        newData.cookieToken = cookieToken
        newData.gameToken = gameToken
        newData.genshinServer = genshinServer
        newData.genshinServerName = genshinServerName
        newData.genshinUID = genshinUID
        newData.genshinNicname = genshinNicname
        newData.level = level
        newData.ltoken = ltoken
        newData.mid = mid
        newData.misheHead = misheHead
        newData.misheNicname = misheNicname
        newData.stoken = stoken
        newData.stuid = stuid
        let _ = AppPersistence.shared.save()
        fetchAccounts()
    }
}
