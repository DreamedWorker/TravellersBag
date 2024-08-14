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
    @Published var announcements: [Announcement] = []
    
    /// 获取被设为默认的账号
    func fetchList() {
        defaultHoyo = nil
        do {
            let result = try context?.fetch(HoyoAccounts.fetchRequest())
            if let surelyResult = result {
                defaultHoyo = surelyResult.filter({$0.stuid! == MMKV.default()!.string(forKey: "default_account_stuid")!}).first!
            }
        } catch {
            ContentMessager.shared.showErrorDialog(msg: error.localizedDescription)
        }
    }
    
    /// 打开本机的兼容层软件
    func openWineApp() {
        if MMKV.default()!.bool(forKey: "use_layer", defaultValue: true) {
            let task = Process()
            task.launchPath = "/bin/zsh"
            task.arguments = ["-c", "open -a \(MMKV.default()!.string(forKey: "layer_name", defaultValue: "CrossOver.app")!)"]
            task.launch()
            return
        }
        if MMKV.default()!.bool(forKey: "use_command", defaultValue: false) {
            let task = Process()
            task.launchPath = "/bin/zsh"
            task.arguments = ["-c", MMKV.default()!.string(forKey: "command_detail", defaultValue: "echo hello") ?? "echo hello"]
            task.launch()
            return
        }
    }
    
    /// 获取实时便签
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
                    ContentMessager.shared.showErrorDialog(msg: error.localizedDescription)
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
    
    /// 获取通知列表
    func fetchAnnouncement() async throws {
        let result = try await AnnouncementService.shared.fetchAnnouncement()
        DispatchQueue.main.async {
            self.announcements = result
        }
    }
    
    /// 刷新通知列表
    func refreshAnnouncement() async throws {
        let localFile = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(component: "announcement.json").path().removingPercentEncoding!
        if FileManager.default.fileExists(atPath: localFile) {
            FileHandler.shared.writeUtf8String(path: localFile, context: "")
        } else {
            FileManager.default.createFile(atPath: localFile, contents: "".data(using: .utf8))
        }
        let result = try await AnnouncementService.shared.fetchFromNetwork()
        DispatchQueue.main.async {
            self.announcements = result
        }
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
