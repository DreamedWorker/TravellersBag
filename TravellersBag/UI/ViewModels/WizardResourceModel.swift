//
//  WizardResourceModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/25.
//

import Foundation
import xxHash_Swift
import SwiftyJSON
import Zip

class WizardResourceModel : ObservableObject {
    let resRoot = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName)!.appending(component: "resources")
    let resImgs = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName)!
        .appending(component: "resources").appending(component: "imgs")
    let resJson = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName)!
        .appending(component: "resources").appending(component: "json")
    let fs = FileManager.default
    let meta = "https://metadata.snapgenshin.com/Genshin/CHS/Meta.json"
    
    
    @Published var uiState = WizardResourceData()
    @Published var imagesDownloadList: [String] =
    ["AvatarIcon", "AvatarIconCircle", "AchievementIcon", "Bg", "ChapterIcon", "EquipIcon",
     "NameCardIcon", "NameCardPic", "Property", "RelicIcon", "Skill", "Talent"]
    @Published var showDownloadBtn: Bool = false
    @Published var staticJsonCount: Int = 0
    @Published var canIndex: Bool = false
    
    /// 创建静态资源基本文件环境
    func mkdir() {
        if !fs.fileExists(atPath: resRoot.toStringPath()) {
            try! fs.createDirectory(at: resRoot, withIntermediateDirectories: true)
            try! fs.createDirectory(at: resImgs, withIntermediateDirectories: true)
            try! fs.createDirectory(at: resJson, withIntermediateDirectories: true)
        }
    }
    
    func fetchMetaFile() async throws {
        func writeDownloadTime() {
            TBCore.shared.configSetValue(key: "metaLastDownloaded", data: Int(Date().timeIntervalSince1970))
        }
        let metaFile = resJson.appending(component: "meta.json")
        let metaRequest = URLRequest(url: URL(string: meta)!)
        if fs.fileExists(atPath: metaFile.toStringPath()) {
            let currentTime = Int(Date().timeIntervalSince1970)
            let lastTime = TBCore.shared.configGetConfig(forKey: "metaLastDownloaded", def: 0)
            if currentTime - lastTime > 432000 {
                try await httpSession().download2File(url: metaFile, req: metaRequest)
                writeDownloadTime()
            }
        } else {
            try await httpSession().download2File(url: metaFile, req: metaRequest)
            writeDownloadTime()
        }
        let metaList = try JSONSerialization.jsonObject(with: Data(contentsOf: metaFile)) as! [String:String]
        DispatchQueue.main.async { [self] in
            uiState.jsonList = metaList
            showDownloadBtn = true
        }
    }
    
    /// 下载文本资源
    func downloadStaticJsonResource() async {
        func calculateHash(url: URL, hash: String) -> Bool {
            let digetsted = try! XXH64.digestHex(String(contentsOf: url, encoding: .utf8)).uppercased()
            if digetsted == hash {
                return true
            } else {
                return false
            }
        }
        func downloadFiles() async throws {
            for singleFile in self.uiState.jsonList {
                DispatchQueue.main.async { self.staticJsonCount += 1 }
                if singleFile.key.contains("/") {
                    let names = singleFile.key.split(separator: "/")
                    let request = URLRequest(url: URL(string: "https://metadata.snapgenshin.com/Genshin/CHS/\(names[0])/\(names[1]).json")!)
                    let tempDir = resJson.appending(component: String(names[0]))
                    if !fs.fileExists(atPath: tempDir.toStringPath()) {
                        try! fs.createDirectory(at: tempDir, withIntermediateDirectories: true)
                    }
                    let tempFile = resJson.appending(component: String(names[0])).appending(component: "\(names[1]).json")
                    if fs.fileExists(atPath: tempFile.toStringPath()) {
                        if calculateHash(url: tempFile, hash: singleFile.value) {
                            continue // 如果本地文件的xxh64hash值与meta中的值相等 说明没有变化 不需要下载 跳过这个文件
                        } else {
                            try await httpSession().download2File(url: tempFile, req: request)
                            try await Task.sleep(for: .seconds(0.5))
                        }
                    } else {
                        try await httpSession().download2File(url: tempFile, req: request)
                        try await Task.sleep(for: .seconds(0.5))
                    }
                } else {
                    let tempFile = resJson.appending(component: String("\(singleFile.key).json"))
                    let request = URLRequest(url: URL(string: "https://metadata.snapgenshin.com/Genshin/CHS/\(singleFile.key).json")!)
                    if fs.fileExists(atPath: tempFile.toStringPath()) {
                        if calculateHash(url: tempFile, hash: singleFile.value) {
                            continue
                        } else {
                            try await httpSession().download2File(url: tempFile, req: request)
                            try await Task.sleep(for: .seconds(0.5))
                        }
                    } else {
                        try await httpSession().download2File(url: tempFile, req: request)
                        try await Task.sleep(for: .seconds(0.5))
                    }
                }
            }
        }
        
        do {
            try await downloadFiles()
            DispatchQueue.main.async { [self] in
                uiState.showJsonDownload = false
                staticJsonCount = 0
                canIndex = true
            }
        } catch TBErrors.avatarDownloadError {
            DispatchQueue.main.async { [self] in
                uiState.showJsonDownload = false
                uiState.fatalMsg = TBErrors.avatarDownloadError.localizedDescription
                uiState.fatalAlert = true
                uiState.canGoNext = false
            }
        } catch {
            DispatchQueue.main.async { [self] in
                uiState.showJsonDownload = false
                uiState.fatalMsg = error.localizedDescription
                uiState.fatalAlert = true
                uiState.canGoNext = false
            }
        }
    }
    
    func indexAvatars() {
        do {
            let innerDir = resJson.appending(component: "Avatar")
            if !fs.fileExists(atPath: innerDir.toStringPath()) {
                throw TBErrors.avatarDownloadError
            }
            let fileCount = try! fs.contentsOfDirectory(atPath: innerDir.toStringPath())
            if uiState.jsonList.keys.map({$0}).filter({$0.contains("Avatar/")}).count != fileCount.count {
                throw TBErrors.avatarDownloadError
            }
            var allAvatars: [JSON] = []
            for i in fileCount {
                allAvatars.append(try JSON(data: String(contentsOf: innerDir.appending(component: i), encoding: .utf8).data(using: .utf8)!))
            }
            allAvatars = allAvatars.sorted(by: { $0["Id"].intValue < $1["Id"].intValue }) // 排序 然后输出
            fs.createFile(atPath: resJson.appending(component: "Avatar.json").toStringPath(), contents: allAvatars.description.data(using: .utf8))
            uiState.successfulAlert = true
            TBCore.shared.configSetValue(key: "staticLastUpdated", data: Int(Date().timeIntervalSince1970))
            TBCore.shared.configSetValue(key: "staticWizardDownloaded", data: true)
            uiState.canGoNext = true
        } catch TBErrors.avatarDownloadError {
            uiState.fatalMsg = TBErrors.avatarDownloadError.localizedDescription
            uiState.fatalAlert = true
            uiState.canGoNext = false
        } catch {
            uiState.fatalMsg = error.localizedDescription
            uiState.fatalAlert = true
            uiState.canGoNext = false
        }
    }
    
    func checkBeforeDownload(url: String) {
        let name = String(url.split(separator: "/").last!)
        let file = resImgs.appending(component: name)
        if fs.fileExists(atPath: file.toStringPath()) {
            try! fs.removeItem(at: file) // 如果文件存在就先删除旧的
        }
    }
    
    func postDownloadEvent(url: URL, name: String, dismiss: @escaping () -> Void) {
        try! fs.moveItem(at: url, to: resImgs.appending(component: "\(name).zip"))
        let dir = resImgs.appending(component: name)
        if fs.fileExists(atPath: dir.toStringPath()) { try! fs.removeItem(at: dir) }
        try! fs.createDirectory(at: dir, withIntermediateDirectories: true)
        do {
            try Zip.unzipFile(resImgs.appending(component: "\(name).zip"), destination: dir, overwrite: true, password: nil)
            try fs.removeItem(at: resImgs.appending(component: "\(name).zip"))
            DispatchQueue.main.async {
                dismiss()
            }
        } catch {
            DispatchQueue.main.async {
                dismiss()
                self.uiState.fatalMsg = "解压文件时出错：\(error.localizedDescription)"
                self.uiState.fatalAlert = true
                if self.fs.fileExists(atPath: dir.toStringPath()) { try! self.fs.removeItem(at: dir) }
            }
        }
    }
}
