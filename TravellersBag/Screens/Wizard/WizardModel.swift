//
//  WizardModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/15.
//

import Foundation
import SwiftyJSON
import Zip

class WizardModel: NSObject, ObservableObject, URLSessionDownloadDelegate {
    private lazy var urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    private var downloadTask: URLSessionDownloadTask?
    private var savePath: URL?
    
    let staticRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appending(component: "globalStatic")
    let fs = FileManager.default
    @Published var showEverything = false
    @Published var showFirstDialog = false
    @Published var metaList: [String] = []
    @Published var metaCount = 1
    
    @Published var errMsg = ""
    @Published var showErr = false
    @Published var downloadState: Float = 0
    @Published var showDownloadSheet = false
    @Published var downloadFinished = false
    
    @Published var imagesDownloadList: [String] =
    ["AvatarIcon", "AvatarIconCircle", "AchievementIcon", "Bg", "ChapterIcon", "EquipIcon",
     "NameCardIcon", "NameCardPic", "Property", "RelicIcon", "Skill", "Talent"]
    
    /// 显示meta.json中的数据
    func showNeedDownloadFiles() async throws {
        let metaFile = staticRoot.appending(component: "Meta.json")
        func readAndParse() {
            DispatchQueue.main.async {
                do {
                    let json = try JSONSerialization.jsonObject(with: Data(contentsOf: metaFile))
                    self.metaList = (json as! [String: String]).keys.map({$0}).sorted()
                } catch {
                    self.errMsg = error.localizedDescription
                    self.showErr = true
                }
            }
        }
        if fs.fileExists(atPath: metaFile.path().removingPercentEncoding!) {
            readAndParse()
        } else {
            let request = URLRequest(url: URL(string: "https://static-next.snapgenshin.com/d/meta/metadata/Genshin/CHS/Meta.json")!)
            try await httpSession().download2File(url: metaFile, req: request)
            readAndParse()
        }
    }
    
    /// 下载静态资源
    func downloadCloudStaticData() async throws {
        let partRoot = staticRoot.appending(component: "cloud")
        // 每次下载都会删除此前的内容，确保json是完整的
        if fs.fileExists(atPath: partRoot.toStringPath()) {
            try! fs.removeItem(at: partRoot)
        }
        try! fs.createDirectory(at: partRoot, withIntermediateDirectories: true)
        for singleFile in metaList {
            if singleFile.contains("/") {
                let names = singleFile.split(separator: "/")
                let tempDir = partRoot.appending(component: String(names[0]))
                if !fs.fileExists(atPath: tempDir.path().removingPercentEncoding!) {
                    try! fs.createDirectory(at: tempDir, withIntermediateDirectories: true)
                }
                let tempFile = partRoot.appending(component: String(names[0])).appending(component: "\(names[1]).json")
                let request = URLRequest(url: URL(string: "https://static-next.snapgenshin.com/d/meta/metadata/Genshin/CHS/\(names[0])/\(names[1]).json")!)
                try await httpSession().download2File(url: tempFile, req: request)
                try await Task.sleep(for: .seconds(0.5))
            } else {
                let tempFile = partRoot.appending(component: String("\(singleFile).json"))
                let request = URLRequest(url: URL(string: "https://static-next.snapgenshin.com/d/meta/metadata/Genshin/CHS/\(singleFile).json")!)
                try await httpSession().download2File(url: tempFile, req: request)
                try await Task.sleep(for: .seconds(0.5))
            }
            DispatchQueue.main.async {
                if self.metaCount != self.metaList.count {
                    self.metaCount += 1
                }
            }
        }
    }
    
    /// 将分散的角色信息合一
    func indexAvatars() throws {
        let outDir = staticRoot.appending(component: "cloud")
        if !fs.fileExists(atPath: outDir.toStringPath()) {
            throw TBErrors.indexFileError("目标文件夹不存在，你尚未下载资源。")
        }
        let innerDir = outDir.appending(component: "Avatar")
        if !fs.fileExists(atPath: innerDir.toStringPath()) {
            throw TBErrors.indexFileError("下载的资源不完整，请重新下载。")
        }
        let lists = try fs.contentsOfDirectory(at: innerDir, includingPropertiesForKeys: nil)
        var allAvatars: [JSON] = []
        for i in lists { // 读取json 并直接加入列表 这样可以直接得到array
            allAvatars.append(try JSON(data: String(contentsOf: i).data(using: .utf8)!))
        }
        let avatarIndex = outDir.appending(component: "Avatar.json")
        if fs.fileExists(atPath: avatarIndex.toStringPath()) {
            try! fs.removeItem(at: avatarIndex)
        }
        allAvatars = allAvatars.sorted(by: { $0["Id"].intValue < $1["Id"].intValue }) // 排序 然后输出
        fs.createFile(atPath: avatarIndex.toStringPath(), contents: allAvatars.description.data(using: .utf8))
    }
    
    func startDownload(url: String) {
        //检查目录是否存在
        let dir = staticRoot.appending(component: "images")
        if !fs.fileExists(atPath: dir.toStringPath()) {
            try! fs.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        let name = String(url.split(separator: "/").last!)
        let file = dir.appending(component: name)
        if fs.fileExists(atPath: file.toStringPath()) {
            try! fs.removeItem(at: file) // 如果文件存在就先删除旧的
        }
        savePath = file
        showDownloadSheet = true
        downloadTask = urlSession.downloadTask(with: URLRequest(url: URL(string: url)!))
        downloadTask?.resume() // 启动任务
    }
    
    /// 取消下载任务
    func cancelDownload() {
        showDownloadSheet = false
        downloadTask?.cancel()
        downloadTask = nil
        savePath = nil
        downloadState = 0
    }
    
    /// 显示一个错误弹窗
    func showErrMsg(msg: String) {
        showErr = true; errMsg = msg
    }
    
    // MARK: 实现下载会话委托的函数 第一个用于下载完成后移动文件 第二个用于处理下载进度
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if fs.fileExists(atPath: savePath!.toStringPath()) {
            try! fs.removeItem(at: savePath!)
        }
        try! fs.moveItem(at: location, to: savePath!)
        let dir = staticRoot.appending(component: "images").appending(component: String(savePath!.lastPathComponent.split(separator: ".")[0]))
        if fs.fileExists(atPath: dir.toStringPath()) { try! fs.removeItem(at: dir) }
        try! fs.createDirectory(at: dir, withIntermediateDirectories: true)
        do {
            try Zip.unzipFile(savePath!, destination: dir, overwrite: true, password: nil)
            DispatchQueue.main.async {
                self.showDownloadSheet = false
                self.downloadFinished = true
            }
        } catch {
            DispatchQueue.main.async {
                self.showDownloadSheet = false
                self.showErrMsg(msg: "解压文件时出错：\(error.localizedDescription)")
                if self.fs.fileExists(atPath: dir.toStringPath()) { try! self.fs.removeItem(at: dir) }
            }
        }
    }
    
    func urlSession(
        _ session: URLSession, downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64
    ) {
        DispatchQueue.main.async {
            let calculatedProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            self.downloadState = calculatedProgress
        }
    }
}
