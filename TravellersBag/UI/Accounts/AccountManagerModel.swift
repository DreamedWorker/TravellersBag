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
    @Published var showFetchFatalToast = false
    @Published var fatalInfo = ""
    @Published var accountsHoyo: [HoyoAccounts] = [] // 水社账号列表
    @Published var showQRCodeWindow = false
    @Published var qrCodeImg: NSImage = NSImage()
    private var picURL: String = ""
    @Published var qrScanState = ""
    
    func fetchAccounts() {
        accountsHoyo.removeAll()
        do {
            let result = try context?.fetch(HoyoAccounts.fetchRequest())
            accountsHoyo = result ?? []
        } catch {
            fatalInfo = error.localizedDescription
            showFetchFatalToast = true
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
                        let newData = HoyoAccounts(context: self.context!)
                        if self.accountsHoyo.count == 0 { // 如果没有账号则自动将刚添加的用作默认
                            newData.activeAccount = true
                        }
                        newData.cookieToken = cookieToken
                        newData.gameToken = gameToken
                        newData.genshinServer = hk4e["region"].stringValue
                        newData.genshinServerName = hk4e["genshinName"].stringValue
                        newData.genshinUID = hk4e["genshinUid"].stringValue
                        newData.genshinNicname = hk4e["genshinNicname"].stringValue
                        newData.level = hk4e["level"].stringValue
                        newData.ltoken = ltoken
                        newData.mid = stoken["mid"].stringValue
                        newData.misheHead = sheBasic["avatar_url"].stringValue
                        newData.misheNicname = sheBasic["nickname"].stringValue
                        newData.stoken = stoken["stoken"].stringValue
                        newData.stuid = result["uid"].stringValue
                        let _ = AppPersistence.shared.save()
                        LocalEnvironment.shared.setStringValue(key: "default_account_stuid", value: result["uid"].stringValue)
                        LocalEnvironment.shared.setStringValue(key: "default_account_stoken", value: stoken["stoken"].stringValue)
                        LocalEnvironment.shared.setStringValue(key: "default_account_mid", value: stoken["mid"].stringValue)
                        self.fetchAccounts()
                        self.showQRCodeWindow = false
                    }
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
    
    func cancelOp() {
        qrCodeImg = NSImage()
        picURL = ""
        fatalInfo = ""
        qrScanState = ""
        showFetchFatalToast = false
    }
    
    /// 完善账号条目
    func updateGameData(user: HoyoAccounts) async {
    }
    
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
}
