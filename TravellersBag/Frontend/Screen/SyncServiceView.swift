//
//  SyncServiceView.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/6/2.
//

import SwiftUI
import SwiftData
import SwiftyJSON

struct SyncServiceView: View {
    @Environment(\.modelContext) private var operation
    @Query private var htPassports: [HutaoPassport]
    @StateObject private var viewModel = SyncServiceViewModel()
    
    var body: some View {
        NavigationStack {
            if let account = htPassports.first {
                Form {
                    Section {
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .foregroundStyle(.accent)
                                    .frame(width: 72, height: 72)
                                Text(account.normalizedUserName).font(.title.bold())
                            }
                            Spacer()
                        }
                    }
                    Section {
                        HStack {
                            Label("sync.service.expire", systemImage: "gauge.with.needle")
                            Spacer()
                            Text(account.gachaLogExpireAt).foregroundStyle(.secondary)
                        }
                        HStack {
                            Label("sync.service.developer", systemImage: "command")
                            Spacer()
                            Text("\(account.isLicensedDeveloper)").foregroundStyle(.secondary)
                        }
                    }
                    Section {
                        ForEach(viewModel.uiState.gachaEntries) { entry in
                            SingleGachaEntry(entry: entry, account: account) { info in
                                viewModel.uiState.alertMate.showAlert(msg: info)
                            }
                        }
                        Text("sync.service.errorTip").font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .formStyle(.grouped)
                .onAppear {
                    viewModel.initSomething(model: operation)
                    Task {
                        await viewModel.fetchPersonalGachaEntries(account: account, refresh: { neoAuth in
                            htPassports.first!.auth = neoAuth
                            try! operation.save()
                        })
                    }
                }
            } else {
                LoginPane()
            }
        }
        .alert(
            viewModel.uiState.alertMate.title,
            isPresented: $viewModel.uiState.alertMate.showIt,
            actions: {},
            message: { Text(viewModel.uiState.alertMate.msg) }
        )
    }
}

extension SyncServiceView {
    struct SingleGachaEntry: View {
        @Environment(\.modelContext) private var operation
        let entry: HutaoService.HutaoGachaEntry.Datum
        let account: HutaoPassport
        let sendMsg: (String) -> Void
        
        var body: some View {
            VStack {
                HStack(spacing: 8) {
                    Label(
                        String.localizedStringWithFormat(NSLocalizedString("sync.service.uid", comment: ""), entry.uid),
                        systemImage: "list.bullet.clipboard.fill"
                    )
                    Spacer()
                    Text(String.localizedStringWithFormat(
                        NSLocalizedString("sync.service.uidCount", comment: ""),
                        String(entry.itemCount)
                    )).foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    Spacer()
                    Button(
                        action: {
                            Task {
                                do {
                                    let thisUID = entry.uid
                                    var delete = RequestBuilder.buildRequest(method: .GET, host: Endpoints.HomaSnapGenshin, path: "/GachaLog/Delete", queryItems: [.init(name: "Uid", value: thisUID)])
                                    delete.setValue("Bearer \(account.auth)", forHTTPHeaderField: "Authorization")
                                    let (result, _) = try await URLSession.shared.data(for: delete)
                                    let response = try JSON(data: result)
                                    DispatchQueue.main.async {
                                        sendMsg(response["message"].stringValue)
                                    }
                                } catch {
                                    DispatchQueue.main.async {
                                        sendMsg(String.localizedStringWithFormat(
                                            NSLocalizedString("sync.service.error.delete", comment: ""), error.localizedDescription)
                                        )
                                    }
                                }
                            }
                        },
                        label: {
                            Text("sync.service.action.delete").foregroundStyle(.red)
                        }
                    )
                    Button("sync.service.action.download") {
                        let thisUID = entry.uid
                        let records = try! operation.fetch(
                            FetchDescriptor(predicate: #Predicate<GachaItem>{ $0.uid == thisUID })
                        )
                        Task {
                            do {
                                let cloudRecords = try await HutaoService.fetchRecords(auth: account.auth, uid: thisUID)
                                DispatchQueue.main.async {
                                    var storedCount = 0
                                    for singleCloudRecord in cloudRecords.data {
                                        if records.contains(where: { $0.id == String(singleCloudRecord.id) }) {
                                            continue
                                        }
                                        let item = GachaItem(
                                            uid: thisUID,
                                            id: String(singleCloudRecord.id),
                                            name: StaticHelper.getNameById(id: String(singleCloudRecord.itemID)),
                                            time: singleCloudRecord.time.dateFromISO2NormalString(),
                                            rankType: StaticHelper.getItemRank(key: String(singleCloudRecord.itemID)),
                                            itemType: (String(singleCloudRecord.itemID).count == 5) ? "武器" : "角色",
                                            gachaType: String(singleCloudRecord.gachaType)
                                        )
                                        self.operation.insert(item)
                                        storedCount += 1
                                    }
                                    try! self.operation.save()
                                    sendMsg(String.localizedStringWithFormat(
                                        NSLocalizedString("sync.service.info.recordDownload", comment: ""),
                                        thisUID, String(storedCount)
                                    ))
                                }
                            } catch {
                                await MainActor.run {
                                    sendMsg(String.localizedStringWithFormat(
                                        NSLocalizedString("sync.service.error.recordDownload", comment: ""),
                                        error.localizedDescription
                                    ))
                                }
                            }
                        }
                    }
                    Button("sync.service.action.upload") {
                        let thisUID = entry.uid
                        let auth = account.auth
                        Task {
                            do {
                                let records = try! operation.fetch(
                                    FetchDescriptor(predicate: #Predicate<GachaItem>{ $0.uid == thisUID })
                                )
                                let msg = try await HutaoService.uploadRecords(records: records, auth: auth, uid: thisUID)
                                DispatchQueue.main.async {
                                    sendMsg(msg)
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    sendMsg(String.localizedStringWithFormat(
                                        NSLocalizedString("sync.service.error.upload", comment: ""), error.localizedDescription)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

extension SyncServiceView {
    struct LoginPane: View {
        @StateObject private var viewModel = SyncServiceViewModel()
        @Query private var htPassports: [HutaoPassport]
        @Environment(\.modelContext) private var operation
        
        var body: some View {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "gyroscope")
                                .resizable()
                                .foregroundStyle(.accent)
                                .frame(width: 72, height: 72)
                            Text("sync.login.title").font(.title.bold())
                            Text("sync.login.exp").foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                Section {
                    TextField("sync.login.username", text: $viewModel.uiState.username)
                    SecureField("sync.login.password", text: $viewModel.uiState.password)
                }
                Section {
                    HStack {
                        Spacer()
                        Button("sync.login", action: {
                            Task {
                                await viewModel.login { tempAccount in
                                    self.operation.insert(tempAccount)
                                    try! operation.save()
                                }
                            }
                        })
                    }
                    HStack {
                        Text("sync.login.serviceTip").font(.footnote).foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }.formStyle(.grouped)
        }
    }
}
