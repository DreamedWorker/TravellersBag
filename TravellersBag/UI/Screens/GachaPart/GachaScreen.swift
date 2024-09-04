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
    @StateObject private var viewModel = GachaModel.shared
    @State private var selectedPart: GachaPart = .ViewAll
    
    @State private var showDelete = false
    @State private var showUpdate = false
    
    var body: some View {
        ZStack{}.frame(width: 0, height: 0).onAppear { viewModel.initSomething(context: dataManager) }
        if viewModel.hasUser {
            DialogsPane
            TabView(selection: $selectedPart, content: {
                DataViewAll.tabItem { Text("gacha.tab.view_all") }.tag(GachaPart.ViewAll)
            })
            .navigationTitle(Text("home.sider.gacha"))
            .toolbar {
                ToolbarItem {
                    Button(action: { showUpdate = true }, label: { Image(systemName: "clock.arrow.2.circlepath").help("gacha.update.title") })
                }
                ToolbarItem {
                    Button(
                        action: {
                            let panel = NSSavePanel()
                            panel.message = NSLocalizedString("gacha.toolbar.export.message", comment: "")
                            panel.allowedContentTypes = [.json]
                            panel.directoryURL = URL(string: NSHomeDirectory())
                            panel.canCreateDirectories = true
                            panel.begin { result in
                                if result == NSApplication.ModalResponse.OK {
                                    GachaService.shared.exportRecords2UIGFv4(
                                        record: viewModel.gachaList,
                                        uid: HomeController.shared.currentUser!.genshinUID!, fileUrl: panel.url!)
                                    HomeController.shared.showInfomationDialog(msg: "导出成功！")
                                }
                            }
                        },
                        label: { Image(systemName: "square.and.arrow.up").help("gacha.toolbar.export") }
                    )
                }
                ToolbarItem {
                    Button(action: { showDelete = true }, label: { Image(systemName: "trash").help("gacha.more.delete") })
                }
            }
        } else {
            NoUserPane
                .navigationTitle(Text("home.sider.gacha"))
        }
    }
    
    private var DataViewAll: some View {
        let character = viewModel.gachaList
            .filter { $0.gachaType == viewModel.characterGacha || $0.gachaType == "400" }
            .sorted(by: { Int($0.id!)! < Int($1.id!)! }) // 按照时间先后顺序原地排序（才发现这个id才是真正排序时的依据 用time代表的时间戳一定出事）
        let weapon = viewModel.gachaList
            .filter({ $0.gachaType == viewModel.weaponGacha }).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        let resident = viewModel.gachaList
            .filter({ $0.gachaType == viewModel.residentGacha }).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        let collection = viewModel.gachaList
            .filter({ $0.gachaType == viewModel.collectionGacha }).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        return ScrollView {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 8) {
                    GachaNormalCard(rootList: character, gachaIcon: "figure.walk", gachaName: "gacha.all.character_title")
                    GachaNormalCard(rootList: weapon, gachaIcon: "fork.knife", gachaName: "gacha.all.weapon_title")
                    GachaNormalCard(rootList: resident, gachaIcon: "app.gift", gachaName: "gacha.all.resident_title")
                    GachaNormalCard(rootList: collection, gachaIcon: "person.3", gachaName: "gacha.all.collection_title")
                }
            }
        }
    }
    
    /// 无用户页面
    private var NoUserPane: some View {
        return VStack {
            Image("gacha_waiting_for")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
            Text("character.forbid.no_user").padding(.vertical, 8)
                .font(.title3).bold()
            MDLikeTile(
                leadingIcon: "arrow.clockwise",
                endIcon: "arrow.forward",
                title: NSLocalizedString("character.forbid.rerfresh", comment: ""),
                onClick: {
                    viewModel.hasUser = HomeController.shared.currentUser != nil
                }
            ).frame(maxWidth: 450)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
    }
    
    /// 弹窗集合
    private var DialogsPane: some View {
        return ZStack{}
            .frame(width: 0, height: 0)
            .alert(
                "gacha.delete.title", isPresented: $showDelete,
                actions: {
                    Button("app.cancel", action: { showDelete = false })
                    Button("app.confirm", action: {
                        viewModel.deleteRecordsFromCoreData()
                        showDelete = false
                    })
                },
                message: { Text("gacha.delete.msg") }
            )
            .alert(
                "gacha.update.title", isPresented: $showUpdate,
                actions: {
                    Button("app.cancel", action: { showUpdate = false })
                    Button("gacha.update.from_hk4e", action: {
                        showUpdate = false
                        HomeController.shared.showLoadingDialog(msg: "正在从云端拉取数据，请保持互联网通畅直至操作完成。")
                        Task { await viewModel.updateFromHk4e() }
                    })
                    Button("gacha.update.from_uigf", action: {
                        var openPanel = NSOpenPanel()
                        openPanel.allowedContentTypes = [.json]; openPanel.allowsMultipleSelection = false
                        openPanel.message = NSLocalizedString("gacha.no_data_import_from_uigf4", comment: "")
                        openPanel.begin { result in
                            if result == NSApplication.ModalResponse.OK {
                                if let url = openPanel.url {
                                    showUpdate = false
                                    viewModel.updateFromUigf(url: url)
                                }
                            }
                        }
                    })
                },
                message: { Text("gacha.update.msg") }
            )
    }
    
    private func timeTransfer(d: Date, detail: Bool = true) -> String {
        let df = DateFormatter()
        df.dateFormat = (detail) ? "yyyy-MM-dd HH:mm:ss" : "yyMMdd"
        return df.string(from: d)
    }
}

#Preview {
    GachaScreen()
}
