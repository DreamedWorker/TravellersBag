//
//  HutaoLogin.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/5.
//

import SwiftUI
import SwiftData
import SwiftyJSON

struct HutaoLogin: View {
    @StateObject private var model = HutaoLoginModel()
    let dismiss: () -> Void
    @State private var deleteCloud = false
    
    var body: some View {
        NavigationStack {
            if let surelyPassport = model.passport {
                HStack {
                    Text(String.localizedStringWithFormat(NSLocalizedString("hutao.title", comment: ""), surelyPassport.normalizedUserName))
                        .font(.title2).bold()
                    Spacer()
                }.padding(.bottom, 4)
                Form {
                    HStack {
                        Label("hutao.ExpireAt", systemImage: "timer")
                        Spacer()
                        Text(surelyPassport.gachaLogExpireAt).foregroundStyle(.secondary)
                    }
                    if model.gachaCloudRecord.count > 0 {
                        ForEach(model.gachaCloudRecord) { entry in
                            VStack {
                                HStack(spacing: 8, content: {
                                    Image(systemName: "waveform.circle").font(.title3)
                                    VStack(alignment: .leading, content: {
                                        Text(String.localizedStringWithFormat(NSLocalizedString("hutao.gacha.uid", comment: ""), entry.id))
                                        Text(
                                            String.localizedStringWithFormat(
                                                NSLocalizedString("hutao.gacha.count", comment: ""), String(entry.ItemCount))
                                        ).font(.callout).foregroundStyle(.secondary)
                                    })
                                    Spacer()
                                    Button(
                                        action: {
                                            Task { /*await viewModel.updateRecordFromHutao()*/ }
                                        },
                                        label: { Image(systemName: "square.and.arrow.down.on.square") }
                                    ).help("hutao.gacha.sync_with_cloud")
                                    Button(
                                        action: { deleteCloud = true },
                                        label: { Image(systemName: "trash").foregroundStyle(.red) }
                                    ).help("hutao.gacha.delete")
                                })
                                HStack {
                                    Spacer()
                                    Button("hutao.gacha.sync", action: { model.fetchRecordInfo(isRefresh: true) })
                                    Button("hutao.gacha.upload", action: {
                                        Task {
//                                            await viewModel.uploadGachaRecord(isFullUpload: entry.ItemCount == 0)
                                        }
                                    }).buttonStyle(BorderedProminentButtonStyle())
                                }
                            }
                        }
                    }
                }
                .formStyle(.grouped)
                .onAppear { model.fetchRecordInfo() }
            } else {
                Image("hutao_passport_login").resizable().frame(width: 72, height: 72)
                Text("hutao.login").font(.title).bold()
                Text("hutao.loginP")
                Form {
                    TextField("hutao.login.email", text: $model.email)
                    SecureField("hutao.login.password", text: $model.pasword)
                }.formStyle(.grouped)
                Text("hutao.loginP2").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction, content: {
                Button("app.cancel", action: {
                    model.dismissBefore(); dismiss()
                })
            })
            if model.passport == nil {
                ToolbarItem(placement: .confirmationAction, content: {
                    Button("app.confirm", action: {
                        Task { await model.tryLogin() }
                    }).disabled(model.email.isEmpty || model.pasword.isEmpty)
                })
            }
        }
        .onAppear {
            _ = model.getCurrentPassport()
        }
        .alert(model.alertMate.msg, isPresented: $model.alertMate.showIt, actions: {})
        .alert(
            "hutao.gacga.deleteDialog", isPresented: $deleteCloud,
            actions: {
                Button("app.cancel", role: .cancel, action: { deleteCloud = false })
                Button("app.confirm", role: .destructive, action: { Task { await model.deleteCloudRecord() } })
            },
            message: { Text("hutao.gacga.deleteDialogP") }
        )
    }
}

private class HutaoLoginModel: ObservableObject {
    @Published var email = ""
    @Published var pasword = ""
    @Published var alertMate = AlertMate()
    @Published var passport: HutaoPassport? = nil
    @Published var gachaCloudRecord: [HutaoRecordEntry] = []
    
    let fs = FileManager.default
    let hutaoRecordRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "libHutao")
    var recordInfo: JSON? = nil
    
    init() {
        if !fs.fileExists(atPath: hutaoRecordRoot.toStringPath()) {
            try! fs.createDirectory(at: hutaoRecordRoot, withIntermediateDirectories: true)
        }
    }
    
    func dismissBefore() {
        email = ""; pasword = ""
    }
    
    @MainActor func getCurrentPassport() -> HutaoPassport? {
        let query = FetchDescriptor<HutaoPassport>()
        let result = try? tbDatabase.mainContext.fetch(query).first
        passport = result
        return result
    }
    
    func tryLogin() async {
        do {
            let result = try await TBHutaoService.loginPassport(username: email, password: pasword)
            let userInfo = try await TBHutaoService.userInfo(auth: result["data"].stringValue)
            let neoAccount = HutaoPassport(
                auth: result["data"].stringValue, gachaLogExpireAt: userInfo["GachaLogExpireAt"].stringValue,
                isLicensedDeveloper: userInfo["IsLicensedDeveloper"].boolValue, isMaintainer: userInfo["IsMaintainer"].boolValue,
                normalizedUserName: userInfo["NormalizedUserName"].stringValue, userName: userInfo["UserName"].stringValue)
            try await TBDatabaseOperation.write2db(item: neoAccount)
            DispatchQueue.main.async { [self] in
                _ = getCurrentPassport()
                email = ""; pasword = ""
            }
        } catch {
            makeAlert(msg: "无法登录你的通行证：\(error.localizedDescription)")
        }
    }
    
    /// 加载（刷新）本地的云祈愿记录缓存
    @MainActor func fetchRecordInfo(isRefresh: Bool = false) {
        func getDataFromNetwork() {
            fs.createFile(atPath: recordFile.toStringPath(), contents: nil)
            Task {
                do {
                    let context = try await TBHutaoService.gachaEntries(hutao: passport!)
                    FileHandler.shared.writeUtf8String(path: recordFile.toStringPath(), context: context.rawString()!)
                    DispatchQueue.main.async { [self] in
                        recordInfo = context
                        for i in context.arrayValue {
                            gachaCloudRecord.append(
                                HutaoRecordEntry(id: i["Uid"].stringValue, Excluded: i["Excluded"].boolValue, ItemCount: i["ItemCount"].intValue)
                            )
                        }
                        gachaCloudRecord = gachaCloudRecord.filter({ $0.id == getDefaultAccount()?.gameInfo.genshinUID ?? "" })
                    }
                } catch {
                    makeAlert(msg: String.localizedStringWithFormat(
                        NSLocalizedString("hutao.error.fetch_gacha_info", comment: ""), error.localizedDescription)
                    )
                }
            }
        }
        
        recordInfo = nil
        gachaCloudRecord.removeAll()
        let recordFile = hutaoRecordRoot.appending(component: "record_info.json")
        if !isRefresh {
            if !fs.fileExists(atPath: recordFile.toStringPath()) {
                fs.createFile(atPath: recordFile.toStringPath(), contents: nil)
                getDataFromNetwork()
            } else {
                let context = FileHandler.shared.readUtf8String(path: recordFile.toStringPath())
                if context != "" || !context.isEmpty {
                    do {
                        recordInfo = try JSON(data: context.data(using: .utf8)!)
                        for i in recordInfo!.arrayValue {
                            gachaCloudRecord.append(
                                HutaoRecordEntry(id: i["Uid"].stringValue, Excluded: i["Excluded"].boolValue, ItemCount: i["ItemCount"].intValue)
                            )
                        }
                        gachaCloudRecord = gachaCloudRecord.filter({ $0.id == getDefaultAccount()?.gameInfo.genshinUID ?? "" })
                    } catch {
                        getDataFromNetwork()
                    }
                }
            }
        } else {
            getDataFromNetwork()
        }
    }
    
    func deleteCloudRecord() async {
        do {
            let result = try await TBHutaoService.deleteGachaRecord(
                uid: getDefaultAccount()!.gameInfo.genshinUID, hutao: passport!
            )
            DispatchQueue.main.async {
                self.fetchRecordInfo(isRefresh: true)
                self.alertMate.showAlert(msg: result["message"].string ?? "删除操作执行成功")
            }
        } catch {
            makeAlert(msg: "删除失败，\(error.localizedDescription)")
        }
    }
    
    private func makeAlert(msg: String) {
        DispatchQueue.main.async {
            self.alertMate.showAlert(msg: msg)
        }
    }
}
