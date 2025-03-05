//
//  WizardResViewModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/3/5.
//

import Foundation
import xxHash_Swift
import SwiftyJSON
import Zip

class WizardResViewModel: ObservableObject, @unchecked Sendable {
    /// 可供下载的图像包
    var imagesDownloadList: [String] =
    ["AvatarIcon", "AvatarIconCircle", "AchievementIcon", "Bg", "ChapterIcon", "EquipIcon",
     "NameCardIcon", "NameCardPic", "Property", "RelicIcon", "Skill", "Talent"]
    /// 文本类资源清单文件
    let meta = "https://metadata.snapgenshin.com/Genshin/CHS/Meta.json"
    /// 资产文件存放根目录
    let staticRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "resource")
    var resImgs: URL? = nil
    var resJson: URL? = nil
    
    @Published var alertMate = AlertMate()
    @Published var showJsonDownloading: Bool = false
    @Published var showImageDownloading: Bool = false
    /// 下载中的json文件数
    @Published var staticJsonCount: Int = 0
    @Published var finalCount: Int = 0
    /// 当前文件下载的百分比进度
    @Published var downloadProgress: Float = 0.0
    
    init() {
        startup()
    }
    
    /// 初始化资源文件夹
    private func startup() {
        resImgs = staticRoot.appending(component: "imgs")
        resJson = staticRoot.appending(component: "jsons")
        if !FileManager.default.fileExists(atPath: staticRoot.toStringPath()) {
            try! FileManager.default.createDirectory(at: staticRoot, withIntermediateDirectories: true)
            try! FileManager.default.createDirectory(at: resImgs!, withIntermediateDirectories: true)
            try! FileManager.default.createDirectory(at: resJson!, withIntermediateDirectories: true)
        }
    }
    
    /// 下载选定的图像资源（压缩包）【在完成下载并解压成功或失败时会删除压缩包】
    func startDownload(url: String) {
        let fileAddr = "https://static-zip.snapgenshin.cn/\(url).zip"
        let mgr = DownloadManager(
            progressEvt: { progress in
                self.downloadProgress = progress
            },
            finishedEvt: { location in
                let fs = FileManager.default
                let localFile = self.resImgs!.appending(component: "\(url).zip")
                if fs.fileExists(atPath: localFile.toStringPath()) {
                    try! fs.removeItem(at: localFile)
                }
                try! fs.moveItem(at: location, to: localFile)
                let dir = self.resImgs!.appending(component: String(localFile.lastPathComponent.split(separator: ".")[0]))
                if fs.fileExists(atPath: dir.toStringPath()) { try! fs.removeItem(at: dir) }
                try! fs.createDirectory(at: dir, withIntermediateDirectories: true)
                do {
                    try Zip.unzipFile(localFile, destination: dir, overwrite: true, password: nil)
                    try fs.removeItem(at: localFile)
                    DispatchQueue.main.async { [self] in
                        showImageDownloading = false
                        downloadProgress = 0
                    }
                } catch {
                    DispatchQueue.main.async { [self] in
                        showImageDownloading = false
                        alertMate.showAlert(
                            msg: String.localizedStringWithFormat(
                                NSLocalizedString("wizard.res.error.jsonDownload", comment: ""),
                                error.localizedDescription),
                            type: .Error
                        )
                        downloadProgress = 0
                        if fs.fileExists(atPath: localFile.toStringPath()) { try! fs.removeItem(at: localFile) }
                    }
                }
            }
        )
        mgr.startDownload(fileUrl: fileAddr)
    }
}

/// 负责处理静态文本资源的元数据下载
extension WizardResViewModel {
    /// 下载所需的静态文本资源
    func downloadTextRes() async -> Result<Int, any Error> {
        do {
            let list = await downloadMetaFile()
            let mid = try await downloadJsonFilesInWizard(indexes: list)
            try indexAvatars(indexes: mid)
            return .success(0x1735000F)
        } catch {
            return .failure(error)
        }
    }
    
    /// 下载元数据文件并写入下载时间（读取本地的除外）
    private func downloadMetaFile() async -> [String : String] {
        func writeDownloadTime() {
            UserDefaults.standard.set(Int(Date().timeIntervalSince1970), forKey: "metaLastDownloaded")
        }
        func readLocalFile() -> [String : String] {
            let contents = try? JSONSerialization.jsonObject(with: Data(contentsOf: metaFile)) as? [String:String]
            DispatchQueue.main.async {
                self.finalCount = contents?.count ?? 0
            }
            if let content = contents {
                return content
            } else {
                return [:]
            }
        }
        func downloadIt() async -> [String : String] {
            var result: [String : String] = [:]
            do {
                try await URLSession.shared.download2File(url: metaFile, req: metaRequest)
                result = readLocalFile()
            } catch {
                result = [:]
            }
            writeDownloadTime()
            return result
        }
        
        let metaFile = resJson!.appending(component: "meta.json")
        let metaRequest = URLRequest(url: URL(string: meta)!)
        if FileManager.default.fileExists(atPath: metaFile.toStringPath()) {
            let currentTime = Int(Date().timeIntervalSince1970)
            let lastTime = UserDefaults.standard.integer(forKey: "metaLastDownloaded")
            if currentTime - lastTime >= 432000 {
                return await downloadIt()
            } else {
                return readLocalFile()
            }
        } else {
            return await downloadIt()
        }
    }
}

extension WizardResViewModel {
    func calculateHash(url: URL, hash: String) -> Bool {
        let digetsted = try! XXH64.digestHex(String(contentsOf: url, encoding: .utf8)).uppercased()
        if digetsted == hash {
            return true
        } else {
            return false
        }
    }
    
    /// 下载具体文件
    func downloadJsonFilesInWizard(indexes: [String : String]) async throws -> [String : String] {
        if indexes.isEmpty || indexes.count <= 0 {
            throw NSError(domain: "icu.bluedream.TravellersBag", code: 0x17350001)
        }
        for singleFile in indexes {
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
                        try await URLSession.shared.download2File(url: tempFile, req: request)
                        try await Task.sleep(for: .seconds(0.5))
                    }
                } else {
                    try await URLSession.shared.download2File(url: tempFile, req: request)
                    try await Task.sleep(for: .seconds(0.5))
                }
            } else {
                let tempFile = resJson!.appending(component: String("\(singleFile.key).json"))
                let request = URLRequest(url: URL(string: "https://metadata.snapgenshin.com/Genshin/CHS/\(singleFile.key).json")!)
                if FileManager.default.fileExists(atPath: tempFile.toStringPath()) {
                    if calculateHash(url: tempFile, hash: singleFile.value) {
                        continue
                    } else {
                        try await URLSession.shared.download2File(url: tempFile, req: request)
                        try await Task.sleep(for: .seconds(0.5))
                    }
                } else {
                    try await URLSession.shared.download2File(url: tempFile, req: request)
                    try await Task.sleep(for: .seconds(0.5))
                }
            }
        }
        return indexes
    }
}

extension WizardResViewModel {
    /// 索引角色信息
    func indexAvatars(indexes: [String : String]) throws {
        if indexes.isEmpty || indexes.count <= 0 {
            throw NSError(domain: "icu.bluedream.TravellersBag", code: 0x17350001)
        }
        let innerDir = resJson!.appending(component: "Avatar")
        if !FileManager.default.fileExists(atPath: innerDir.toStringPath()) {
            throw NSError(domain: "icu.bluedream.TravellersBag", code: 0x17350002)
        }
        let fileCount = try! FileManager.default.contentsOfDirectory(atPath: innerDir.toStringPath())
        if indexes.keys.map({$0}).filter({$0.contains("Avatar/")}).count != fileCount.count {
            throw NSError(domain: "icu.bluedream.TravellersBag", code: 0x17350003)
        }
        var allAvatars: [JSON] = []
        for i in fileCount {
            allAvatars.append(try JSON(data: String(contentsOf: innerDir.appending(component: i), encoding: .utf8).data(using: .utf8)!))
        }
        allAvatars = allAvatars.sorted(by: { $0["Id"].intValue < $1["Id"].intValue }) // 排序 然后输出
        FileManager.default.createFile(atPath: resJson!.appending(component: "Avatar.json").toStringPath(), contents: allAvatars.description.data(using: .utf8))
    }
}
