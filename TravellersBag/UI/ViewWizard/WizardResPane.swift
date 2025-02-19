//
//  WizardResPane.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/25.
//

import SwiftUI
import Zip

struct WizardResPane: View {
    @StateObject private var vm = WizardResViewModel()
    
    let goNext: () -> Void
    
    @ViewBuilder
    var body: some View {
        LazyVStack {
            Image(systemName: "tray.full.fill")
                .resizable().scaledToFit()
                .foregroundStyle(.accent)
                .frame(width: 96)
            Text("wizard.res.title")
                .font(.largeTitle).fontWeight(.black)
            Text("wizard.res.exp").padding(.vertical, 2)
            VStack {
                HStack {
                    Label("wizard.res.txt.title", systemImage: "text.quote")
                        .font(.title3)
                    Spacer()
                }.padding(.bottom, 2)
                HStack {
                    Text("wizard.res.txt.version")
                    Spacer()
                    Text("wizard.res.txt.versionAct")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Spacer()
                    Button(
                        "wizard.res.txt.get",
                        action: {
                            vm.showJsonDownloading = true
                            Task {
                                switch await vm.downloadTextRes() {
                                case .success(_):
                                    DispatchQueue.main.async {
                                        vm.showJsonDownloading = false
                                        vm.alertMate.showAlert(
                                            msg: NSLocalizedString("wizard.res.info.jsonDownloadFinished", comment: ""),
                                            type: .Info
                                        )
                                    }
                                case .failure(let failure):
                                    DispatchQueue.main.async {
                                        vm.showJsonDownloading = false
                                        vm.alertMate.showAlert(
                                            msg: String.localizedStringWithFormat(
                                                NSLocalizedString("wizard.res.error.jsonDownload", comment: ""),
                                                failure.localizedDescription),
                                            type: .Error
                                        )
                                    }
                                }
                            }
                        }
                    )
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, x: 4, y: 4))
            VStack {
                HStack {
                    Label("wizard.res.img.title", systemImage: "text.below.photo")
                        .font(.title3)
                    Spacer()
                }.padding(.bottom, 2)
                Text("wizard.res.img.exp")
                    .font(.footnote).foregroundStyle(.secondary)
                List {
                    ForEach(vm.imagesDownloadList, id: \.self) { single in
                        HStack {
                            Label(single, systemImage: "photo.stack")
                            Spacer()
                            Button(
                                "wizard.res.txt.get",
                                action: {
                                    vm.showImageDownloading = true
                                    vm.startDownload(url: single)
                                }
                            )
                                .buttonStyle(BorderlessButtonStyle())
                        }
                        .listRowSeparator(.hidden)
                        .padding(4)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(content: { RoundedRectangle(cornerRadius: 4).stroke(.secondary, lineWidth: 1) })
                    }
                }
                .frame(height: CGFloat(150))
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, x: 4, y: 4))
            Spacer()
            Image(systemName: "info.circle")
                .font(.title3).symbolRenderingMode(.multicolor)
            Text("wizard.res.source")
                .font(.footnote).foregroundStyle(.secondary)
            Divider()
            StyledButton(
                text: "def.next",
                actions: goNext,
                colored: true
            )
        }
        .alert(vm.alertMate.title, isPresented: $vm.alertMate.showIt, actions: {}, message: { Text(verbatim: vm.alertMate.msg) })
        .sheet(isPresented: $vm.showJsonDownloading, content: { JsonDownloadSheet })
        .sheet(isPresented: $vm.showImageDownloading, content: { ImageDownloadSheet })
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 {
                    return nil
                } else {
                    return event
                }
            }
        }
    }
    
    private var JsonDownloadSheet: some View {
        return NavigationStack {
            ProgressView()
            Text("wizard.res.sheetJsonTitle").font(.title).bold().padding(.bottom, 4)
            Text(
                String.localizedStringWithFormat(
                    NSLocalizedString("wizard.res.sheetJsonStatus", comment: ""),
                    String(vm.staticJsonCount), String(vm.finalCount)
                )
            )
        }
        .padding(20)
    }
    
    private var ImageDownloadSheet: some View {
        return NavigationStack {
            Text("wizard.res.sheetImageTitle").font(.title).bold().padding(.bottom, 4)
            ProgressView(value: vm.downloadProgress, total: 1.0)
        }
        .padding(20)
        .frame(maxWidth: 300)
    }
}

class WizardResViewModel: ObservableObject, @unchecked Sendable {
    var imagesDownloadList: [String] =
    ["AvatarIcon", "AvatarIconCircle", "AchievementIcon", "Bg", "ChapterIcon", "EquipIcon",
     "NameCardIcon", "NameCardPic", "Property", "RelicIcon", "Skill", "Talent"]
    let meta = "https://metadata.snapgenshin.com/Genshin/CHS/Meta.json"
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
    
    func startDownload(url: String) {
        let fileAddr = "https://static-zip.snapgenshin.cn/\(url).zip"
        print(fileAddr)
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

#Preview {
    WizardResPane(goNext: {})
}
