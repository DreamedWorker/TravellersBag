//
//  DailyNoteScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/26.
//

import SwiftUI
import SwiftyJSON
import SwiftData

struct DailyNoteScreen: View {
    @StateObject private var vm = DailyNoteModel()
    
    private func getAccount(filePath: String) -> MihoyoAccount? {
        let uid = String(String(filePath.split(separator: "/").last!).split(separator: ".")[0])
        let fetch = try? tbDatabase.mainContext
            .fetch(FetchDescriptor<MihoyoAccount>(predicate: #Predicate { $0.gameInfo.genshinUID == uid } )).first
        return fetch
    }
    
    private func fetchAllAccount() -> [MihoyoAccount] {
        let fetch = try? tbDatabase.mainContext.fetch(FetchDescriptor<MihoyoAccount>())
        return fetch ?? []
    }
    
    var body: some View {
        if vm.notes.isEmpty {
            DefaultPane(
                fetchEvt: { account in
                    Task { await vm.fetchDailynoteInfo(account: account, finishedEvt: { msg in vm.createAlert(msg: msg) }) }
                }
            )
        } else {
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(vm.notes, id: \.self) { it in
                        if let content = try? JSON(data: FileHandler.shared.readUtf8String(path: it).data(using: .utf8)!) {
                            if let account = getAccount(filePath: it) {
                                NoteCell(
                                    dailyContext: content, account: account,
                                    deleteEvt: { vm.deleteNote(path: it) },
                                    refreshEvt: {
                                        Task {
                                            await vm.fetchDailynoteInfo(account: account, finishedEvt: { msg in
                                                DispatchQueue.main.async {
                                                    self.vm.alertMate.showAlert(msg: msg)
                                                }
                                            })
                                        }
                                    }
                                )
                            } else {
                                AbnormalPane(delete: { vm.deleteNote(path: it) })
                            }
                        } else {
                            AbnormalPane(delete: { vm.deleteNote(path: it) })
                        }
                    }
                }
                .padding(4)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: { vm.showAddSheet = true }, label: { Image(systemName: "plus") })
                }
            }
            .alert(vm.alertMate.msg, isPresented: $vm.alertMate.showIt, actions: {})
            .sheet(
                isPresented: $vm.showAddSheet,
                content: {
                    AddNewNote(
                        accounts: fetchAllAccount(),
                        dismiss: { vm.showAddSheet = false },
                        addIt: { account in
                            vm.showAddSheet = false
                            if !vm.checkTheSame(filename: "\(account.gameInfo.genshinUID).json") {
                                Task {
                                    await vm.fetchDailynoteInfo(account: account, finishedEvt: { msg in
                                        DispatchQueue.main.async {
                                            self.vm.alertMate.showAlert(msg: msg)
                                        }
                                    })
                                }
                            } else {
                                vm.alertMate.showAlert(msg: "该账号的便签已经存在！")
                            }
                        }
                    )
                }
            )
        }
    }
}

private struct AbnormalPane: View {
    var delete: () -> Void
    
    var body: some View {
        VStack {
            Image("dailynote_empty").resizable().frame(width: 72, height: 72)
            Text("daily.abnormal.title").font(.title2).bold().padding(.bottom, 8)
            Button("daily.abnormal.delete", action: delete)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, y: 4))
    }
}

private struct DefaultPane: View {
    var fetchEvt: (MihoyoAccount) -> Void
    @State private var alert = AlertMate()
    
    private func showAlert(msg: String) {
        alert.showAlert(msg: msg)
    }
    
    var body: some View {
        VStack {
            Image("dailynote_empty").resizable().frame(width: 72, height: 72)
            Text("daily.empty").font(.title2).bold()
            Button(
                action: {
                    if let account = TBDao.getDefaultAccount() {
                        fetchEvt(account)
                    } else {
                        showAlert(msg: "请先设置一个默认账号再继续。")
                    }
                },
                label: {
                    Label("daily.empty.createFromDef", systemImage: "note.text.badge.plus").padding()
                }
            ).padding(.top, 16)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, y: 4))
        .alert(alert.msg, isPresented: $alert.showIt, actions: {})
    }
}

private class DailyNoteModel: ObservableObject {
    @Published var notes: [String] = []
    @Published var alertMate = AlertMate()
    @Published var showAddSheet = false
    
    private var localDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "note")
    
    init() {
        checkFiles()
    }
    
    private func checkFiles() {
        if !FileManager.default.fileExists(atPath: localDir.toStringPath()) {
            try! FileManager.default.createDirectory(at: localDir, withIntermediateDirectories: true)
        }
        notes.removeAll()
        try? FileManager.default.contentsOfDirectory(atPath: localDir.toStringPath())
            .forEach({ it in notes.append(localDir.appending(component: it).toStringPath()) })
    }
    
    func checkTheSame(filename: String) -> Bool {
        let files = try? FileManager.default.contentsOfDirectory(atPath: localDir.toStringPath())
        if let file = files {
            if file.contains(filename) {
                return true
            } else { return false}
        } else {
            return false
        }
    }
    
    func deleteNote(path: String) {
        try! FileManager.default.removeItem(atPath: path)
        checkFiles()
    }
    
    func fetchDailynoteInfo(account: MihoyoAccount, finishedEvt: @escaping (String) -> Void) async {
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
            let result = try await req.receiveOrThrow()
            writeRemoteContent2Local(uid: account.gameInfo.genshinUID, content: result)
            DispatchQueue.main.async { finishedEvt("加载成功！") }
        } catch {
            DispatchQueue.main.async { finishedEvt("获取信息失败，\(error.localizedDescription)") }
        }
    }
    
    private func writeRemoteContent2Local(uid: String, content: JSON) {
        let localFile = localDir.appending(component: "\(uid).json")
        if !FileManager.default.fileExists(atPath: localFile.toStringPath()) {
            FileManager.default.createFile(atPath: localFile.toStringPath(), contents: nil)
        }
        FileHandler.shared.writeUtf8String(path: localFile.toStringPath(), context: content.rawString()!)
        DispatchQueue.main.async {
            self.checkFiles()
        }
    }
    
    func createAlert(msg: String) {
        DispatchQueue.main.async {
            self.alertMate.showAlert(msg: msg)
        }
    }
}
