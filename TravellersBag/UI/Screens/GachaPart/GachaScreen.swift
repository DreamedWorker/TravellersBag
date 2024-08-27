//
//  GachaScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/23.
//

import SwiftUI

private enum GachaPart {
    case ViewAll
}

struct GachaScreen: View {
    @Environment(\.managedObjectContext) private var dataManager
    @State private var selectedPart: GachaPart = .ViewAll
    @StateObject private var viewModel = GachaModel.shared
    @State private var hasUser = false
    
    var body: some View {
        if hasUser {
            if viewModel.showContextUI {
                TabView(selection: $selectedPart,
                        content:  {
                    generalView.tabItem { Text("gacha.tab.view_all") }.tag(GachaPart.ViewAll)
                })
                .navigationTitle(Text("home.sider.gacha"))
                .toolbar {
                    ToolbarItem {
                        Button(
                            action: {
                                GachaService.shared.exportRecords2UIGFv4(
                                    record: viewModel.gachaList,
                                    uid: HomeController.shared.currentUser!.genshinUID!
                                )
                            },
                            label: { Image(systemName: "square.and.arrow.up").help("gacha.toolbar.export") }
                        )
                    }
                    ToolbarItem {
                        Button(
                            action: {
                            },
                            label: { Image(systemName: "externaldrive.badge.icloud").help("gacha.more.op_with_hutao") }
                        )
                    }
                    ToolbarItem {
                        Button(
                            action: {
                                viewModel.showMoreOption = true
                            },
                            label: { Image(systemName: "ellipsis") }
                        )
                    }
                }
                .sheet(isPresented: $viewModel.showMoreOption, content: { moreOptions })
            } else {
                VStack {
                    Image("gacha_waiting_for").resizable().scaledToFit()
                        .frame(width: 72, height: 72)
                    Text("gacha.no_data.title").font(.title2).bold().padding(.vertical, 8)
                    MDLikeTile(
                        leadingIcon: "externaldrive.badge.icloud", endIcon: "arrow.forward",
                        title: NSLocalizedString("gacha.no_data.get_from_hk4e", comment: ""),
                        onClick: {
                            HomeController.shared.showLoadingDialog(msg: "正在从云端拉取数据，请保持互联网通畅直至操作完成。")
                            Task {
                                do {
                                    try await viewModel.getRecordFromHk4e()
                                } catch {
                                    DispatchQueue.main.async {
                                        HomeController.shared.showErrorDialog(
                                            msg: String.localizedStringWithFormat(
                                                NSLocalizedString("gacha.error.get_authkey", comment: ""),
                                                error.localizedDescription)
                                        )
                                    }
                                }
                            }
                        }).frame(maxWidth: .infinity - 32)
                    MDLikeTile(
                        leadingIcon: "square.and.arrow.down.on.square", endIcon: "arrow.forward",
                        title: NSLocalizedString("gacha.no_data_import_from_uigf4", comment: ""),
                        onClick: {
                            // 似乎这里只有使用 NSOpenPanel 才能暂时获得用户选择的文件的读权限，swiftui的fileImporter修饰符不能 奇怪？！
                            let panel = NSOpenPanel()
                            panel.allowedContentTypes = [.json]; panel.allowsMultipleSelection = false
                            panel.begin(completionHandler: { result in
                                if result == NSApplication.ModalResponse.OK {
                                    if let url = panel.urls.first {
                                        viewModel.getRecordFromUigf(fileContext: try! String(contentsOf: url))
                                    }
                                }
                            })
                        }).frame(maxWidth: .infinity - 32)
                    MDLikeTile(
                        leadingIcon: "arrow.clockwise", endIcon: "arrow.forward",
                        title: NSLocalizedString("gacha.no_data.refresh", comment: ""),
                        onClick: {
                            viewModel.refreshState()
                        }
                    ).frame(maxWidth: .infinity - 32)
                    Text("gacha.no_data.another_account").font(.footnote).foregroundStyle(.secondary)
                }
                .padding(16)
            }
        } else {
            VStack {
                Image("gacha_waiting_for").resizable().scaledToFit()
                    .frame(width: 72, height: 72)
                Text("character.forbid.no_user").padding(.vertical, 8)
                    .font(.title3).bold()
                Button("character.forbid.rerfresh", action: {
                    hasUser = HomeController.shared.currentUser != nil
                })
            }.onAppear {
                viewModel.initSomething(context: dataManager)
                if HomeController.shared.currentUser != nil {
                    hasUser = true
                }
            }
        }
    }
    
    var generalView: some View {
        let character = viewModel.gachaList
            .filter { $0.gachaType == viewModel.characterGacha || $0.gachaType == "400" }
            .sorted(by: { Int($0.id!)! < Int($1.id!)! }) // 按照时间先后顺序原地排序（才发现这个id才是真正排序时的依据 用time代表的时间戳一定出事）
        let weapon = viewModel.gachaList
            .filter({ $0.gachaType == viewModel.weaponGacha }).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        let resident = viewModel.gachaList
            .filter({ $0.gachaType == viewModel.residentGacha }).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        let collection = viewModel.gachaList
            .filter({ $0.gachaType == viewModel.collectionGacha }).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        let beginner = viewModel.gachaList
            .filter({ $0.gachaType == viewModel.beginnerGacha }).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        return ScrollView {
            Grid {
                ScrollView(.horizontal) {
                    HStack(alignment: .top) {
                        GachaNormalCard(rootList: character, gachaIcon: "figure.walk", gachaName: "gacha.all.character_title")
                        GachaNormalCard(rootList: weapon, gachaIcon: "fork.knife", gachaName: "gacha.all.weapon_title")
                        GachaNormalCard(rootList: resident, gachaIcon: "app.gift", gachaName: "gacha.all.resident_title")
                        GachaNormalCard(rootList: collection, gachaIcon: "person.3", gachaName: "gacha.all.collection_title")
                        GachaNormalCard(rootList: beginner, gachaIcon: "backpack", gachaName: "gacha.all.beginner_title")
                    }
                }
            }
        }
    }
    
    var moreOptions: some View {
        return NavigationStack {
            Text("gacha.more.title").font(.title).bold()
            Divider().padding(.horizontal, 8)
            MDLikeTile(
                leadingIcon: "trash", endIcon: "arrow.forward", 
                title: NSLocalizedString("gacha.more.delete", comment: ""),
                onClick: {
                    viewModel.showContextUI = false
                    Task {
                        await viewModel.removeAllData()
                    }
                    viewModel.showMoreOption = false
                    HomeController.shared.showInfomationDialog(msg: NSLocalizedString("gacha.more.msg_delete", comment: ""))
                }
            )
            MDLikeTile(
                leadingIcon: "cloud", endIcon: "arrow.forward",
                title: NSLocalizedString("gacha.more.update_from_hk4e", comment: ""),
                onClick: {}
            )
            MDLikeTile(
                leadingIcon: "arrow.down.doc", endIcon: "arrow.forward",
                title: NSLocalizedString("gacha.more.update_from_uigf", comment: ""),
                onClick: {}
            )
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction, content: {
                Button("app.cancel", action: { viewModel.showMoreOption = false })
                    .buttonStyle(BorderedProminentButtonStyle())
            })
        }
        .frame(minWidth: 420)
    }
}

#Preview {
    GachaScreen()
}
