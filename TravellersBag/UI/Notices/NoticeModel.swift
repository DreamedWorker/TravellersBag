//
//  NoticeModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/9.
//

import Foundation
import CoreData
import MMKV

class NoticeModel : ObservableObject {
    @Published var defaultHoyo: HoyoAccounts? = nil
    @Published var context: NSManagedObjectContext? = nil
    @Published var showDailyNote: Bool = false
    @Published var noteJSON: JSON? = nil
    
    @Published var showError = false
    @Published var errMsg = ""
    
    /// 获取被设为默认的账号
    func fetchList() {
        defaultHoyo = nil
        do {
            let result = try context?.fetch(HoyoAccounts.fetchRequest())
            if let surelyResult = result {
                defaultHoyo = surelyResult.filter({$0.stuid! == MMKV.default()!.string(forKey: "default_account_stuid")!}).first!
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// 打开本机的兼容层软件
    func openWineApp() {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", "open -a CrossOver.app"]
        task.launch()
    }
    
    func fetchDailyNote() async throws {
        let localFile = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(component: "daily_note.json")
        /// 本地函数：从互联网获取实时便签并写入文件
        func fetchFromNetwork() async throws {
            let result = try await self.getDailyNote(user: defaultHoyo!)
            FileHandler.shared.writeUtf8String(path: localFile.path().removingPercentEncoding!, context: result.rawString()!)
            DispatchQueue.main.async {
                self.noteJSON = result
                self.showDailyNote = true
            }
        }
        
        if defaultHoyo != nil {
            if !FileManager.default.fileExists(atPath: localFile.path().removingPercentEncoding!) {
                FileManager.default.createFile(atPath: localFile.path().removingPercentEncoding!, contents: nil)
                try await fetchFromNetwork()
                return
            }
            let fileContext = FileHandler.shared.readUtf8String(path: localFile.path().removingPercentEncoding!)
            if !fileContext.isEmpty || fileContext != "" {
                let result = try JSON(data: fileContext.data(using: .utf8)!)
                DispatchQueue.main.async {
                    self.noteJSON = result
                    self.showDailyNote = true
                }
            } else {
                try await fetchFromNetwork()
            }
        } // 没有登录账号则静默 登录后用户手动获取
    }
    
    /// 刷新便签内容
    func refreshDaily() {
        let localFile = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(component: "daily_note.json")
        showDailyNote = false
        noteJSON = nil
        FileHandler.shared.writeUtf8String(path: localFile.path().removingPercentEncoding!, context: "")
        Task {
            do {
                try await fetchDailyNote()
            } catch {
                DispatchQueue.main.async {
                    self.errMsg = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
    
    /// 获取探索派遣完成数量
    func getExpeditionState() -> Int {
        let list = noteJSON!["expeditions"].arrayValue
        let filterIt = list.filter({ $0["status"].stringValue == "Finished" })
        return filterIt.count
    }
    
    private func getDailyNote(user: HoyoAccounts) async throws -> JSON {
        var req = URLRequest(url: URL(string: "https://api-takumi-record.mihoyo.com/game_record/app/genshin/aapi/widget/v2?")!)
        req.setHost(host: "api-takumi-record.mihoyo.com")
        req.setValue("stuid=\(user.stuid!);stoken=\(user.stoken!);ltuid=\(user.stuid!);ltoken=\(user.ltoken!);mid=\(user.mid!)", forHTTPHeaderField: "Cookie")
        req.setReferer(referer: "https://webstatic.mihoyo.com/")
        req.setUA()
        req.setValue("zh-cn", forHTTPHeaderField: "x-rpc-language")
        req.setValue("v4.1.5-ys_#/ys/daily", forHTTPHeaderField: "x-rpc-page")
        req.setValue("https://webstatic.mihoyo.com", forHTTPHeaderField: "Origin")
        req.setDeviceInfoHeaders()
        req.setXRPCAppInfo(client: "5")
        req.setDS(version: SaltVersion.V2, type: SaltType.X4, include: false)
        return try await req.receiveOrThrow()
    }
}
