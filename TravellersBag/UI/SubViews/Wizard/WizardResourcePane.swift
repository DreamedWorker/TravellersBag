//
//  WizardResourcePane.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/7.
//

import SwiftUI
import SwiftyJSON
import xxHash_Swift
import Zip

extension WizardView {
    struct WizardResourcePane: View {
        @StateObject private var vm = ResourceViewModel()
        let goNext: () -> Void
        
        var body: some View {
            VStack {
                Image(systemName: "square.and.arrow.down.on.square.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.accent)
                    .padding(.bottom, 4)
                Text("wizard.res.title").font(.title).bold()
                Text("wizard.res.description")
                    .padding(.top, 2)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom)
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("wizard.res.staticTitle").bold().font(.title3)
                        Text("wizard.res.staticExplanation")
                            .font(.footnote).foregroundStyle(.secondary)
                        HStack {
                            Spacer()
                            Button("wizard.res.index", action: { vm.indexAvatars() })
                            Button("wizard.res.staticBeforeDl", action: { Task { await vm.downloadTextAssets() }})
                            Button("wizard.res.download", action: {
                                vm.uiState.showJsonDownload = true
                                Task { await vm.downloadStaticJsonAssets() }
                            })
                                .buttonStyle(BorderedProminentButtonStyle())
                        }
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
                    VStack(alignment: .leading) {
                        Text("wizard.res.imageTitle").bold().font(.title3)
                        Text("wizard.res.imageSee").font(.footnote).foregroundStyle(.secondary)
                        List {
                            ForEach(vm.imagesDownloadList, id: \.self) { imageName in
                                HStack {
                                    Text(imageName)
                                    Spacer()
                                    Button("wizard.res.download", action: {
                                        vm.uiState.downloadName = imageName
                                        vm.uiState.showDownloadSheet = true
                                        vm.startDownload(url: "https://static-zip.snapgenshin.cn/\(imageName).zip")
                                    })
                                }
                            }
                        }.frame(height: 100)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
                    Spacer()
                    Image(systemName: "info.circle")
                        .font(.title2).foregroundStyle(.accent)
                        .padding(.bottom, 2)
                    Text("wizard.res.tip")
                        .foregroundStyle(.secondary).font(.footnote)
                    Divider()
                    Button(
                        action: { goNext() },
                        label: { Text("wizard.lang.next").padding(8) }
                    ).buttonStyle(BorderedProminentButtonStyle())
                }
            }
            .onAppear {
                vm.startup()
            }
            .sheet(isPresented: $vm.uiState.showJsonDownload, content: { JsonDownloadSheet })
            .alert(
                String.localizedStringWithFormat(NSLocalizedString("def.operationErrorOccured", comment: ""), vm.uiState.fatalMsg),
                isPresented: $vm.uiState.fatalAlert, actions: {})
            .alert("def.operationSuccessful", isPresented: $vm.uiState.successfulAlert, actions: {})
            .sheet(isPresented: $vm.uiState.showDownloadSheet, content: { ImageDownloadSheet })
        }
        
        private var JsonDownloadSheet: some View {
            return NavigationStack {
                ProgressView()
                Text("wizard.res.sheetJsonTitle").font(.title).bold().padding(.bottom, 4)
                Text(
                    String.localizedStringWithFormat(
                        NSLocalizedString("wizard.res.sheetJsonStatus", comment: ""),
                        String(vm.staticJsonCount), String(vm.uiState.jsonList.count)
                    )
                )
            }
            .padding()
        }
        
        private var ImageDownloadSheet: some View {
            return NavigationStack {
                Text("wizard.res.sheetJsonTitle").font(.title).bold().padding(.bottom, 4)
                ProgressView(value: vm.uiState.downloadState, total: 1.0)
            }
            .padding()
            .frame(maxWidth: 300)
            .toolbar {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button("def.cancel", action: {
                        vm.cancelDownload()
                        vm.uiState.showDownloadSheet = false
                    })
                })
            }
        }
    }
    
    class ResourceViewModel: NSObject, @unchecked Sendable, ObservableObject, URLSessionDownloadDelegate {
        @Published var uiState = WizardResourceData()
        @Published var staticJsonCount: Int = 0
        
        var imagesDownloadList: [String] =
        ["AvatarIcon", "AvatarIconCircle", "AchievementIcon", "Bg", "ChapterIcon", "EquipIcon",
         "NameCardIcon", "NameCardPic", "Property", "RelicIcon", "Skill", "Talent"]
        let meta = "https://metadata.snapgenshin.com/Genshin/CHS/Meta.json"
        let staticRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(component: "resource")
        var resImgs: URL? = nil
        var resJson: URL? = nil
        private var savePath: URL? = nil
        
        private lazy var urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        private var downloadTask: URLSessionDownloadTask? = nil
        
        /// 在本页面可见时调用 判断并生成相关的文件夹
        func startup() {
            resImgs = staticRoot.appending(component: "imgs")
            resJson = staticRoot.appending(component: "jsons")
            if !FileManager.default.fileExists(atPath: staticRoot.toStringPath()) {
                try! FileManager.default.createDirectory(at: staticRoot, withIntermediateDirectories: true)
                try! FileManager.default.createDirectory(at: resImgs!, withIntermediateDirectories: true)
                try! FileManager.default.createDirectory(at: resJson!, withIntermediateDirectories: true)
            }
        }
        
        /// Download Text-class assets (meta-data file will be checked before download task is about to start.)
        @MainActor func downloadTextAssets() async {
            do {
                try await fetchMetaFile()
            } catch {
                DispatchQueue.main.async { [self] in
                    uiState.showJsonDownload = false
                    uiState.fatalMsg = error.localizedDescription
                    uiState.fatalAlert = true
                    uiState.canGoNext = false
                }
            }
        }
        
        /// 下载资产清单文件
        @MainActor private func fetchMetaFile() async throws {
            func writeDownloadTime() {
                UserDefaults.standard.set(Int(Date().timeIntervalSince1970), forKey: "metaLastDownloaded")
            }
            let metaFile = resJson!.appending(component: "meta.json")
            let metaRequest = URLRequest(url: URL(string: meta)!)
            if FileManager.default.fileExists(atPath: metaFile.toStringPath()) {
                let currentTime = Int(Date().timeIntervalSince1970)
                let lastTime = UserDefaults.standard.integer(forKey: "metaLastDownloaded")
                if currentTime - lastTime >= 432000 {
                    try await URLSession.shared.download2File(url: metaFile, req: metaRequest)
                    writeDownloadTime()
                }
            } else {
                try await URLSession.shared.download2File(url: metaFile, req: metaRequest)
                writeDownloadTime()
            }
            let metaList = try JSONSerialization.jsonObject(with: Data(contentsOf: metaFile)) as! [String:String]
            DispatchQueue.main.async {
                self.uiState.jsonList = metaList
            }
        }
        
        /// Download json files.
        @MainActor func downloadStaticJsonAssets() async {
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
            }
            
            if uiState.jsonList.count > 0 {
                do {
                    try await downloadFiles()
                    DispatchQueue.main.async { [self] in
                        uiState.showJsonDownload = false
                        staticJsonCount = 0
                    }
                } catch {
                    DispatchQueue.main.async { [self] in
                        uiState.showJsonDownload = false
                        uiState.fatalMsg = "Error occured while download text-class assets.\(error.localizedDescription)"
                        uiState.fatalAlert = true
                        uiState.canGoNext = false
                    }
                }
            } else {
                DispatchQueue.main.async { [self] in
                    uiState.showJsonDownload = false
                    staticJsonCount = 0
                }
            }
        }
        
        /// 索引部分资源
        func indexAvatars() {
            do {
                let innerDir = resJson!.appending(component: "Avatar")
                if !FileManager.default.fileExists(atPath: innerDir.toStringPath()) {
                    throw NSError(domain: "icu.bluedream.TravellersBag", code: 0x10000001, userInfo: [NSLocalizedDescriptionKey: "wizard.res.errorNotExist"])
                }
                let fileCount = try! FileManager.default.contentsOfDirectory(atPath: innerDir.toStringPath())
                if uiState.jsonList.keys.map({$0}).filter({$0.contains("Avatar/")}).count != fileCount.count {
                    throw NSError(domain: "icu.bluedream.TravellersBag", code: 0x10000001, userInfo: [NSLocalizedDescriptionKey: "wizard.res.errorNotFull"])
                }
                var allAvatars: [JSON] = []
                for i in fileCount {
                    allAvatars.append(try JSON(data: String(contentsOf: innerDir.appending(component: i), encoding: .utf8).data(using: .utf8)!))
                }
                allAvatars = allAvatars.sorted(by: { $0["Id"].intValue < $1["Id"].intValue }) // 排序 然后输出
                FileManager.default.createFile(atPath: resJson!.appending(component: "Avatar.json").toStringPath(), contents: allAvatars.description.data(using: .utf8))
                uiState.successfulAlert = true
                UserDefaults.standard.set(Int(Date().timeIntervalSince1970), forKey: "staticLastUpdated")
                UserDefaults.standard.set(true, forKey: "staticWizardDownloaded")
                UserDefaults.standard.set(true, forKey: "useLocalTextResource")
                uiState.canGoNext = true
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
        
        func urlSession(
            _ session: URLSession, downloadTask: URLSessionDownloadTask,
            didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64
        ) {
            DispatchQueue.main.async {
                let calculatedProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                self.uiState.downloadState = calculatedProgress
            }
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
    }
}

#Preview(body: { WizardView.WizardResourcePane(goNext: {}).padding() })
