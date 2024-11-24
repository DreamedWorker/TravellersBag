//
//  ResourceModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/29.
//

import Foundation
import xxHash_Swift
import SwiftyJSON
import Zip

class ResourceModel: NSObject, ObservableObject, URLSessionDownloadDelegate {
    private lazy var urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    private var downloadTask: URLSessionDownloadTask? = nil
    private var savePath: URL? = nil
    
    let staticRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "resource")
    let meta = "https://metadata.snapgenshin.com/Genshin/CHS/Meta.json"
    @Published var uiState = WizardResourceData()
    var imagesDownloadList: [String] =
    ["AvatarIcon", "AvatarIconCircle", "AchievementIcon", "Bg", "ChapterIcon", "EquipIcon",
     "NameCardIcon", "NameCardPic", "Property", "RelicIcon", "Skill", "Talent"]
    @Published var showDownloadBtn: Bool = false
    @Published var staticJsonCount: Int = 0
    @Published var canIndex: Bool = false
    
    var resImgs: URL? = nil
    var resJson: URL? = nil
    
    func startup() {
        resImgs = staticRoot.appending(component: "imgs")
        resJson = staticRoot.appending(component: "jsons")
        if !FileManager.default.fileExists(atPath: staticRoot.toStringPath()) {
            try! FileManager.default.createDirectory(at: staticRoot, withIntermediateDirectories: true)
            try! FileManager.default.createDirectory(at: resImgs!, withIntermediateDirectories: true)
            try! FileManager.default.createDirectory(at: resJson!, withIntermediateDirectories: true)
        }
    }
    
    func fetchMetaFile() async throws {
        func writeDownloadTime() {
            UserDefaults.configSetValue(key: "metaLastDownloaded", data: Int(Date().timeIntervalSince1970))
        }
        let metaFile = resJson!.appending(component: "meta.json")
        let metaRequest = URLRequest(url: URL(string: meta)!)
        if FileManager.default.fileExists(atPath: metaFile.toStringPath()) {
            let currentTime = Int(Date().timeIntervalSince1970)
            let lastTime = UserDefaults.configGetConfig(forKey: "metaLastDownloaded", def: 0)
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
                    let tempDir = resJson!.appending(component: String(names[0]))
                    if !FileManager.default.fileExists(atPath: tempDir.toStringPath()) {
                        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                    }
                    let tempFile = resJson!.appending(component: String(names[0])).appending(component: "\(names[1]).json")
                    if FileManager.default.fileExists(atPath: tempFile.toStringPath()) {
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
                    let tempFile = resJson!.appending(component: String("\(singleFile.key).json"))
                    let request = URLRequest(url: URL(string: "https://metadata.snapgenshin.com/Genshin/CHS/\(singleFile.key).json")!)
                    if FileManager.default.fileExists(atPath: tempFile.toStringPath()) {
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
            let innerDir = resJson!.appending(component: "Avatar")
            if !FileManager.default.fileExists(atPath: innerDir.toStringPath()) {
                throw TBErrors.avatarDownloadError
            }
            let fileCount = try! FileManager.default.contentsOfDirectory(atPath: innerDir.toStringPath())
            if uiState.jsonList.keys.map({$0}).filter({$0.contains("Avatar/")}).count != fileCount.count {
                throw TBErrors.avatarDownloadError
            }
            var allAvatars: [JSON] = []
            for i in fileCount {
                allAvatars.append(try JSON(data: String(contentsOf: innerDir.appending(component: i), encoding: .utf8).data(using: .utf8)!))
            }
            allAvatars = allAvatars.sorted(by: { $0["Id"].intValue < $1["Id"].intValue }) // 排序 然后输出
            FileManager.default.createFile(atPath: resJson!.appending(component: "Avatar.json").toStringPath(), contents: allAvatars.description.data(using: .utf8))
            uiState.successfulAlert = true
            UserDefaults.configSetValue(key: "staticLastUpdated", data: Int(Date().timeIntervalSince1970))
            UserDefaults.configSetValue(key: "staticWizardDownloaded", data: true)
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
    
    func startDownload(url: String) {
        if !FileManager.default.fileExists(atPath: resImgs!.toStringPath()) {
            try! FileManager.default.createDirectory(at: resImgs!, withIntermediateDirectories: true)
        }
        let name = String(url.split(separator: "/").last!)
        let file = resImgs!.appending(component: name)
        if FileManager.default.fileExists(atPath: file.toStringPath()) {
            try! FileManager.default.removeItem(at: file) // 如果文件存在就先删除旧的
        }
        savePath = file
        uiState.showDownloadSheet = true
        downloadTask = urlSession.downloadTask(with: URLRequest(url: URL(string: url)!))
        downloadTask?.resume() // 启动任务
    }
    
    /// 取消下载任务
    func cancelDownload() {
        uiState.showDownloadSheet = false
        downloadTask?.cancel()
        downloadTask = nil
        savePath = nil
        uiState.downloadState = 0
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let fs = FileManager.default
        if fs.fileExists(atPath: savePath!.toStringPath()) {
            try! fs.removeItem(at: savePath!)
        }
        try! fs.moveItem(at: location, to: savePath!)
        let dir = resImgs!.appending(component: String(savePath!.lastPathComponent.split(separator: ".")[0]))
        if fs.fileExists(atPath: dir.toStringPath()) { try! fs.removeItem(at: dir) }
        try! fs.createDirectory(at: dir, withIntermediateDirectories: true)
        do {
            try Zip.unzipFile(savePath!, destination: dir, overwrite: true, password: nil)
            try fs.removeItem(at: savePath!)
            DispatchQueue.main.async { [self] in
                uiState.showDownloadSheet = false
                uiState.downloadState = 0
            }
        } catch {
            DispatchQueue.main.async { [self] in
                uiState.showDownloadSheet = false
                uiState.downloadState = 0
                uiState.fatalMsg = "下载失败：\(error.localizedDescription)"
                uiState.fatalAlert = true
                if fs.fileExists(atPath: savePath!.toStringPath()) { try! fs.removeItem(at: savePath!) }
            }
        }
    }
    
    func urlSession(
        _ session: URLSession, downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64
    ) {
        DispatchQueue.main.async {
            let calculatedProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            self.uiState.downloadState = calculatedProgress
        }
    }
}
