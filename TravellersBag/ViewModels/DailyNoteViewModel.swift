//
//  DailyNoteViewModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/12.
//

import Foundation
import SwiftyJSON

extension DailyNoteView {
    
    class DailyNoteViewModel: ObservableObject {
        let noteStorage = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(component: "DailyNote")
        
        @Published var notes: [UINoteUnit] = []
        @Published var shouldShowContent: Bool = false
        @Published var alertMate = AlertMate()
        
        init() {
            if !FileManager.default.fileExists(atPath: noteStorage.toStringPath()) {
                try! FileManager.default.createDirectory(at: noteStorage, withIntermediateDirectories: true)
            }
        }
        
        /// 读取本地输入并显示到屏幕上
        func getSomething() {
            notes.removeAll(); shouldShowContent = false
            if let localNotes = try? FileManager.default.contentsOfDirectory(atPath: noteStorage.toStringPath()) {
                localNotes.forEach({ simplePath in
                    let path = noteStorage.appending(component: simplePath).toStringPath()
                    let name = String(path.split(separator: "/").last!.split(separator: ".").first!)
                    let context = try? JSON(data: String(contentsOfFile: path, encoding: .utf8).data(using: .utf8) ?? Data.empty)
                    notes.append(UINoteUnit(id: name, content: context))
                })
            }
            if notes.count > 0 {
                shouldShowContent = true
            } else {
                shouldShowContent = false
            }
        }
        
        /// 获取或更新本地存储
        @MainActor func fetchDailyNote(account: MihoyoAccount) async {
            let builtURL = ApiEndpoints.shared.getWidgetFull(uid: account.gameInfo.genshinUID)
            do {
                var req = URLRequest(url: URL(string: builtURL)!)
                req.setXRPCAppInfo(client: "5")
                req.setHost(host: "api-takumi-record.mihoyo.com")
                req.setIosUA()
                req.setReferer(referer: "https://webstatic.mihoyo.com/")
                req.setValue("https://webstatic.mihoyo.com", forHTTPHeaderField: "Origin")
                req.setDeviceInfoHeaders()
                req.setDS(version: .V2, type: .X4, q: "role_id=\(account.gameInfo.genshinUID)&server=cn_gf01", include: false)
                let result = try await JSON(data: req.receiveOrBlackData())
                if result.contains(where: { $0.0 == "ProgramError" }) {
                    throw NSError(domain: "icu.bluedream.TravellersBag", code: 0x10010002, userInfo: nil)
                }
                let localFile = noteStorage.appending(component: "\(account.gameInfo.genshinUID).json")
                if !FileManager.default.fileExists(atPath: localFile.toStringPath()) {
                    FileManager.default.createFile(atPath: localFile.toStringPath(), contents: nil)
                }
                try! result.rawString()!.write(to: localFile, atomically: true, encoding: .utf8)
                getSomething()
            } catch {
                alertMate.showAlert(msg: "获取便筹时出现问题：\(error.localizedDescription)")
            }
        }
        
        /// 添加新便签
        @MainActor func addNewNote2Local(account: MihoyoAccount) async {
            let localFile = noteStorage.appending(component: "\(account.gameInfo.genshinUID).json")
            if FileManager.default.fileExists(atPath: localFile.toStringPath()) {
                alertMate.showAlert(msg: NSLocalizedString("daily.error.existed", comment: ""))
            } else { // 通过判断防止重复添加
                await fetchDailyNote(account: account)
            }
        }
        
        /// 删除便签 （手动清空缓存列表 因为如果文件夹为空则不会做任何事）
        func deleteNote(note: UINoteUnit) {
            let requiredFile = noteStorage.appending(component: "\(note.id).json")
            try! FileManager.default.removeItem(at: requiredFile)
            getSomething()
        }
    }
}
