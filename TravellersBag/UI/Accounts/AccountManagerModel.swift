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
        let result = await AccountService.shared.fetchQRCode()
        if result.evtState {
            DispatchQueue.main.async {
                let pic = result.data as! String
                self.picURL = pic
                self.dealImg(pic: pic)
            }
        } else {
            DispatchQueue.main.async {
                self.qrScanState = result.data as! String
            }
        }
    }
    
    /// 查询二维码状态 并进行后续操作
    func queryQRState() async {
        let comps = URLComponents(string: picURL)
        if let ticket = comps?.queryItems?.filter({$0.name == "ticket"}).first {
            let result = await AccountService.shared.queryCodeState(ticket: ticket.value!)
            if result.evtState {
                // 应该在这里设置相同账号拦截事件
                let checkForRepeating = try! JSON(data: (result.data as! String).data(using: .utf8)!)
                let checkSame = try! JSON(data: checkForRepeating["data"]["payload"]["raw"].stringValue.data(using: .utf8)!)
                let sameCount = self.accountsHoyo.filter({$0.stuid! == checkSame["uid"].stringValue}).count
                if sameCount == 0 {
                    let stokenResult = await AccountService.shared.pullUserSToken(gameTokenData: result.data as! String)
                    if stokenResult.evtState {
                        let stokenStruct = stokenResult.data as! HoyoUser
                        DispatchQueue.main.async {
                            let newUser = HoyoAccounts(context: self.context!)
                            newUser.stuid = stokenStruct.stuid
                            newUser.stoken = stokenStruct.stoken
                            newUser.mid = stokenStruct.mid
                            let save = AppPersistence.shared.save()
                            if save.evtState {
                                self.showQRCodeWindow = false
                                self.fetchAccounts()
                            } else {
                                self.qrScanState = save.data as! String
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.qrScanState = stokenResult.data as! String
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.qrScanState = "发现重复账号，已阻止本次登录。"
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.qrScanState = result.data as! String
                }
            }
        } else {
            DispatchQueue.main.async {
                self.qrScanState = "二维码参数为空，无法查询状态。"
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
        let result = await AccountService.shared.pullUserSheInfo(uid: user.stuid!) // 需要转义头像链接的url，把反斜杠去掉
        if result.evtState {
            print(String(data: (result.data as! Data), encoding: .utf8)!)
            let genshinBasic = await AccountService.shared.pullHk4eBasic(user: user)
            if genshinBasic.evtState {
                print(String(data: (genshinBasic.data as! Data), encoding: .utf8)!)
                let ltokenPull = await AccountService.shared.pullUserLtoken(user: user)
                if ltokenPull.evtState {
                    print(ltokenPull.data as! String)
                }
            }
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
}
