//
//  AccountModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/16.
//

import Foundation
import CoreData
import AppKit
import CoreImage.CIFilterBuiltins

class AccountModel: ObservableObject {
    static let shared = AccountModel()
    @Published var context: NSManagedObjectContext? = nil
    @Published var accounts: [ShequAccount] = []
    @Published var picData: JSON? = nil
    
    @Published var qrCodeImg: NSImage = NSImage()
    @Published var showQRCodeWindow = false // 二维码登录弹窗
    @Published var showCookieWindow = false // cookie登录弹窗
    @Published var qrScanState = ""
    @Published var cookieInput = ""
    
    private var picURL: String = ""
    
    private init(){}
    
    func initSomething(inContext: NSManagedObjectContext) {
        context = inContext
        fetchPicData() // 顺序不可颠倒
        fetchAccounts()
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
            self.buildErrorMessage(
                msg: String.localizedStringWithFormat(
                    NSLocalizedString("user.error.fetch_qr_code", comment: ""),
                    error.localizedDescription)
            )
        }
    }
    
    /// 查询二维码状态 并进行后续操作
    func queryQRState() async {
        let comps = URLComponents(string: picURL)
        do {
            if let ticket = comps?.queryItems?.filter({$0.name == "ticket"}).first { //智能获取ticket
                let result = try await JSON(data: AccountService.shared.queryCodeState(ticket: ticket.value!))
                let sameCount = self.accounts.filter({$0.stuid! == result["uid"].stringValue}).count
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
                    let other = try await pullAndPutGameInfo(uid: hk4e["genshinUid"].stringValue)
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
                        HomeController.shared.showInfomationDialog(msg: NSLocalizedString("user.add_successfully", comment: ""))
                        self.cancelOp()
                    }
                } else {
                    throw NSError(domain: "ui.login.with.qr", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: NSLocalizedString("user.error.repeated_acc", comment: "")
                    ])
                }
            } else {
                throw NSError(domain: "ui.login.with.qr", code: -2, userInfo: [
                    NSLocalizedDescriptionKey: NSLocalizedString("user.error.qr_no_token", comment: "")
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
            do {
                let sameCount = self.accounts.filter({$0.stuid! == String(stuid!)}).count
                if sameCount == 0 {
                    let cookieToken = try await AccountService.shared.pullUserCookieToken(uid: String(stuid!), stoken: String(stoken!), mid: String(mid!))
                    let gameToken = try await AccountService.shared.pullUserGameToken(stoken: String(stoken!), mid: String(mid!))
                    let sheBasic = try await JSON(data: AccountService.shared.pullUserSheInfo(uid: String(stuid!)))
                    let hk4e = try await JSON(data: AccountService.shared.pullHk4eBasic(uid: String(stuid!), stoken: "\(String(stoken!))==.CAE=", mid: String(mid!)))
                    let ltoken = try await AccountService.shared.pullUserLtoken(uid: String(stuid!), stoken: "\(String(stoken!))==.CAE=", mid: String(mid!))
                    let other = try await pullAndPutGameInfo(uid: hk4e["genshinUid"].stringValue)
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
                        self.cookieInput = ""
                        self.showCookieWindow = false
                    }
                } else {
                    throw NSError(domain: "ui.login.with.qr", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: NSLocalizedString("user.error.repeated_acc", comment: "")
                    ])
                }
            } catch {
                DispatchQueue.main.async {
                    self.qrScanState = error.localizedDescription
                }
            }
        } else {
            DispatchQueue.main.async {
                self.qrScanState = NSLocalizedString("user.cookie.type_error", comment: "")
            }
        }
    }
    
    /// 清空一些变量，然后便于重新获取
    func cancelOp() {
        qrCodeImg = NSImage()
        picURL = ""
        showCookieWindow = false
        showQRCodeWindow = false
        qrScanState = ""
    }
    
    /// 读取用户列表
    func fetchAccounts() {
        do {
            accounts.removeAll()
            accounts = try context!.fetch(ShequAccount.fetchRequest())
        } catch {
            accounts.removeAll()
            HomeController.shared.showErrorDialog(
                msg: String.localizedStringWithFormat(
                    NSLocalizedString("user.error.fetch_all_users", comment: ""), error.localizedDescription)
            )
        }
    }
    
    /// 提取原神账号头像链接
    func getGenshinHeadUrl(id: String) -> String {
        let fileName = picData![id]["iconPath"].stringValue
        return "https://enka.network/ui/\(fileName).png"
    }
    
    /// 加载头像索引 这应当优先于【读取用户列表】加载！
    private func fetchPicData() {
        let url = Bundle.main.url(forResource: "pfps", withExtension: "json")!.path().removingPercentEncoding!
        picData = try! JSON(data: FileHandler.shared.readUtf8String(path: url).data(using: .utf8)!)
    }
    
    private func buildErrorMessage(msg: String) {
        DispatchQueue.main.async {
            HomeController.shared.showErrorDialog(msg: msg)
        }
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
    
    /// 将从镜像站获取到的数据写入本地，然后返回头像ID用于CoreData存储。
    private func pullAndPutGameInfo(uid: String) async throws -> String {
        let result = try await CharacterService.shared.pullCharactersFromEnka(gameUID: uid)
        let charactersFromEnka = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(component: "characters_from_enka-\(uid).json").path().removingPercentEncoding!
        if !FileManager.default.fileExists(atPath: charactersFromEnka) {
            FileManager.default.createFile(atPath: charactersFromEnka, contents: nil)
        } else {
            FileHandler.shared.writeUtf8String(path: charactersFromEnka, context: "")
        }
        FileHandler.shared.writeUtf8String(path: charactersFromEnka, context: String(data: result, encoding: .utf8)!)
        let json = try JSON(data: result)
        return String(json["playerInfo"]["profilePicture"]["id"].intValue)
    }
    
    private func writeAccount(
        cookieToken: String, gameToken: String, genshinServer: String, genshinServerName: String, genshinUID: String,
        genshinNicname: String, level: String, ltoken: String, mid: String, misheHead: String, misheNicname: String,
        stoken: String, stuid: String, genshinPicId: String
    ) {
        let newData = ShequAccount(context: context!)
        if accounts.count == 0 { // 如果没有账号则自动将刚添加的用作默认
            newData.active = true
            LocalEnvironment.shared.setStringValue(key: "default_account_stuid", value: stuid)
            LocalEnvironment.shared.setStringValue(key: "default_account_stoken", value: stoken)
            LocalEnvironment.shared.setStringValue(key: "default_account_mid", value: mid)
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
        fetchAccounts()
    }
}
