//
//  GachaView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/13.
//

import SwiftUI
import SwiftData
import SwiftyJSON

struct GachaView: View {
    @Environment(\.modelContext) private var mc
    @StateObject private var vm = GachaViewModel()
    @State private var thisAccountGachaRecords: [GachaItem] = []
    @Query private var accounts: [MihoyoAccount]
    @State private var displayAccount: MihoyoAccount? = nil
    @State private var showWaitingSheet: Bool = false
    @State private var showHistory: Bool = false
    @State private var selectAccount: Bool = false
    
    var body: some View {
        NavigationStack {
            if displayAccount != nil {
                VStack {
                    if thisAccountGachaRecords.isEmpty {
                        VStack {
                            Image("dailynote_empty").resizable().frame(width: 72, height: 72)
                            Text("gacha.empty.title").font(.title2).bold().padding(.bottom, 16)
                            Button(
                                action: {
                                    showWaitingSheet = true
                                    Task {
                                        let counts = await processHk4e2CoreData(
                                            hk4eList: vm.updateDataFromCloud(user: displayAccount!),
                                            account: displayAccount!
                                        )
                                        DispatchQueue.main.async {
                                            vm.alertMate.showAlert(msg: "已从云端为\(displayAccount!.gameInfo.genshinUID)同步了\(counts)条记录。")
                                        }
                                    }
                                },
                                label: { Text("gacha.empty.fetch").padding() }
                            )
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, y: 4))
                    } else {
                        let character = thisAccountGachaRecords
                            .filter { $0.gachaType == vm.characterGacha || $0.gachaType == "400" }
                            .sorted(by: { Int($0.id)! < Int($1.id)! })
                        let weapon = thisAccountGachaRecords
                            .filter({ $0.gachaType == vm.weaponGacha }).sorted(by: { Int($0.id)! < Int($1.id)! })
                        let resident = thisAccountGachaRecords
                            .filter({ $0.gachaType == vm.residentGacha }).sorted(by: { Int($0.id)! < Int($1.id)! })
                        let collection = thisAccountGachaRecords
                            .filter({ $0.gachaType == vm.collectionGacha }).sorted(by: { Int($0.id)! < Int($1.id)! })
                        if showHistory {
                            GachaHistoryActivity(thisAccountRecord: thisAccountGachaRecords, dismiss: { showHistory = false })
                        } else {
                            ScrollView(.horizontal) {
                                LazyHStack(alignment: .top) {
                                    GachaBulletin(specificData: character, gachaTitle: "gacha.home.avatar")
                                    GachaBulletin(specificData: weapon, gachaTitle: "gacha.home.weapon")
                                    GachaBulletin(specificData: resident, gachaTitle: "gacha.home.resident")
                                    GachaBulletin(specificData: collection, gachaTitle: "gacha.home.collection")
                                }
                                .padding(8)
                            }
                            .toolbar {
                                ToolbarItem {
                                    Button(
                                        action: { selectAccount = true },
                                        label: { Image(systemName: "list.bullet.circle").help("dashboard.menu.another") }
                                    )
                                }
                                ToolbarItem {
                                    Button(
                                        action: { showHistory = true },
                                        label: { Image(systemName: "clock").help("gacha.history") }
                                    )
                                }
                                ToolbarItem {
                                    Button(
                                        action: {
                                            let panel = NSSavePanel()
                                            panel.message = NSLocalizedString("gacha.home.menu.export_p", comment: "")
                                            panel.allowedContentTypes = [.json]
                                            panel.directoryURL = URL(string: NSHomeDirectory())
                                            panel.canCreateDirectories = true
                                            panel.begin { result in
                                                if result == NSApplication.ModalResponse.OK {
                                                    do {
                                                        try UIGF.exportRecords2UIGFv4(
                                                            record: thisAccountGachaRecords,
                                                            uid: displayAccount!.gameInfo.genshinUID,
                                                            fileUri: panel.url!
                                                        )
                                                        vm.alertMate.showAlert(msg: NSLocalizedString("gacha.info.outputOK", comment: ""))
                                                    } catch {
                                                        vm.alertMate.showAlert(
                                                            msg: String.localizedStringWithFormat(
                                                                NSLocalizedString("gacha.error.output", comment: ""),
                                                                error.localizedDescription)
                                                        )
                                                    }
                                                }
                                            }
                                        },
                                        label: {
                                            Image(systemName: "square.and.arrow.up").help("gacha.home.menu.export")
                                        }
                                    )
                                }
                            }
                            .sheet(isPresented: $selectAccount, content: { SelectOtherAccountsProfile })
                        }
                    }
                }
                .toolbar {
                    ToolbarItem {
                        Button(
                            action: {
                                let openPanel = NSOpenPanel()
                                openPanel.allowedContentTypes = [.json]; openPanel.allowsMultipleSelection = false
                                openPanel.message = NSLocalizedString("gacha.home.menu.update_p2", comment: "")
                                openPanel.begin { result in
                                    if result == NSApplication.ModalResponse.OK {
                                        if let url = openPanel.url {
                                            do {
                                                let count = try UIGF.updateFromFile(
                                                    url: url,
                                                    uid: displayAccount!.gameInfo.genshinUID,
                                                    mc: mc,
                                                    oriList: thisAccountGachaRecords
                                                )
                                                vm.alertMate.showAlert(
                                                    msg: String.localizedStringWithFormat(
                                                        NSLocalizedString("gacha.info.update4fileOK", comment: ""),
                                                        String(count)
                                                    )
                                                )
                                            } catch {
                                                vm.alertMate.showAlert(
                                                    msg: String.localizedStringWithFormat(
                                                        NSLocalizedString("gacha.error.update4file", comment: ""),
                                                        error.localizedDescription)
                                                )
                                            }
                                        }
                                    }
                                }
                            },
                            label: { Image(systemName: "square.and.arrow.down").help("gacha.home.menu.import") }
                        )
                    }
                }
            } else {
                VStack {
                    Text("gacha.def.title").font(.title).bold()
                    Form {
                        ForEach(accounts) { account in
                            HStack {
                                Label(account.gameInfo.genshinUID, systemImage: "person.crop.circle")
                                Spacer()
                                Button("gacha.def.select", action: {
                                    displayAccount = account; thisAccountGachaRecords.removeAll()
                                    fetchRequiredContent(account: displayAccount!)
                                })
                            }
                        }
                    }
                }
                .onAppear {
                    if let def = accounts.filter({ $0.active == true }).first {
                        displayAccount = def
                        fetchRequiredContent(account: displayAccount!)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, y: 4))
            }
        }
        .navigationTitle(Text("home.sidebar.gacha"))
        .alert(vm.alertMate.msg, isPresented: $vm.alertMate.showIt, actions: {})
        .sheet(isPresented: $showWaitingSheet, content: { WaitingSheet })
    }
    
    private var SelectOtherAccountsProfile: some View {
        return NavigationStack {
            Text("dashboard.more.title").font(.title).bold()
            Text("dashboard.more.description").multilineTextAlignment(.center)
            Form {
                ForEach(accounts) { user in
                    HStack {
                        Label(user.gameInfo.genshinNicname, systemImage: "person.crop.circle")
                        Spacer()
                        Button("dashboard.more.choose", action: {
                            thisAccountGachaRecords.removeAll(); displayAccount = user
                            fetchRequiredContent(account: displayAccount!)
                            selectAccount = false
                            vm.alertMate.showAlert(msg: NSLocalizedString("def.operationSuccessful", comment: ""))
                        }).buttonStyle(.borderless)
                    }
                }
            }.formStyle(.grouped)
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction, content: {
                Button("def.cancel", action: { selectAccount = false })
            })
        }
    }
    
    private var WaitingSheet: some View {
        return NavigationStack {
            ProgressView()
            Text("gacha.def.waiting").font(.title3).bold().multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func fetchRequiredContent(account: MihoyoAccount) {
        let genshinUID = account.gameInfo.genshinUID
        let fetcher = FetchDescriptor<GachaItem>(predicate: #Predicate{ $0.uid == genshinUID })
        if let results = try? mc.fetch(fetcher) {
            if !results.isEmpty {
                thisAccountGachaRecords.removeAll()
                thisAccountGachaRecords = results
            }
        }
    }
    
    private func processHk4e2CoreData(hk4eList: [JSON], account: MihoyoAccount) -> Int {
        var count = 0
        for one in hk4eList {
            if one["item_id"].stringValue == "10008" { continue }
            if !thisAccountGachaRecords.isEmpty {
                if thisAccountGachaRecords.contains(where: { $0.id == one["id"].stringValue }) { continue }
            } // 自动增量更新配置
            if one["uid"].stringValue != account.gameInfo.genshinUID { continue } //不知道是否会触发
            let neoItem = GachaItem(
                uid: one["uid"].stringValue, id: one["id"].stringValue, name: one["name"].stringValue, time: one["time"].stringValue,
                rankType: one["rank_type"].stringValue, itemType: one["item_type"].stringValue, gachaType: one["gacha_type"].stringValue
            )
            mc.insert(neoItem)
            count += 1
        }
        try! mc.save()
        fetchRequiredContent(account: account)
        showWaitingSheet = false
        return count
    }
}

#Preview {
    GachaView()
}
