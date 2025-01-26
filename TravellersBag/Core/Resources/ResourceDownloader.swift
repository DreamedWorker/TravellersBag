//
//  ResourceDownloader.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/25.
//

import Foundation
import Zip
import xxHash_Swift
import SwiftyJSON

/// 负责处理静态文本资源的元数据下载
// MARK: 这适用于初始化时调用
extension WizardResViewModel {
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

/// 下载完元数据后调用 下载具体文件
// MARK: 这适用于初始化时调用
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

/// 下载完文件后的索引
// MARK: 同时适用于初始化和更新
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
