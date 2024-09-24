//
//  GachaOverview.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/23.
//

import SwiftUI

struct GachaOverview: View {
    @Environment(\.managedObjectContext) private var dataManager
    @StateObject private var viewModel = GachaModel.default
    @State private var gachaPart: GachaPart = .Overview
    @State private var updateAlert = false
    @State private var deleteAlert = false
    
    var body: some View {
        VStack {
            if GlobalUIModel.exported.hasDefAccount() {
                switch viewModel.uiPart {
                case .NoData:
                    NoDataPart.onAppear { viewModel.initSomething(dm: dataManager) }
                case .Showing:
                    Content
                        .toolbar {
                            if gachaPart == .Overview {
                                ToolbarItem {
                                    Button(
                                        action: { updateAlert = true },
                                        label: { Image(systemName: "clock.arrow.2.circlepath").help("gacha.home.menu.update")}
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
                                                    GachaService.shared.exportRecords2UIGFv4(
                                                        record: viewModel.gachaList,
                                                        uid: GlobalUIModel.exported.defAccount!.genshinUID!,
                                                        fileUrl: panel.url!
                                                    )
                                                    GlobalUIModel.exported.makeAnAlert(type: 1, msg: "导出成功！")
                                                }
                                            }
                                        },
                                        label: { Image(systemName: "square.and.arrow.up").help("gacha.home.menu.export")}
                                    )
                                }
                                ToolbarItem {
                                    Button(action: { deleteAlert = true }, label: { Image(systemName: "trash").help("gacha.home.menu.delete")})
                                }
                            }
                        }
                case .LoadedError:
                    Text("app.cancel")
                }
            } else {
                VStack {
                    Button("gacha.login_first", action: { GlobalUIModel.exported.refreshDefAccount() })
                        .buttonStyle(BorderedProminentButtonStyle())
                }
            }
        }
        .alert(
            "app.notice", isPresented: $updateAlert,
            actions: {
                Button("gacha.no_data.cloud", action: {
                    updateAlert = false
                    GlobalUIModel.exported.makeALoading(msg: "我们正在获取数据，请确保全程网络通畅。")
                    Task {
                        await viewModel.updateDataFromCloud()
                    }
                })
                Button("gacha.no_data.file", action: {
                    updateAlert = false
                    let openPanel = NSOpenPanel()
                    openPanel.allowedContentTypes = [.json]; openPanel.allowsMultipleSelection = false
                    openPanel.message = NSLocalizedString("gacha.home.menu.update_p2", comment: "")
                    openPanel.begin { result in
                        if result == NSApplication.ModalResponse.OK {
                            if let url = openPanel.url {
                                viewModel.updateDataFromFile(url: url)
                            }
                        }
                    }
                })
                Button(role: .cancel, action: { updateAlert = false }, label: { Text("app.cancel") })
            },
            message: { Text("gacha.home.menu.update_p") }
        )
        .alert("app.warning", isPresented: $deleteAlert, actions: {
            Button(role: .destructive, action: {
                viewModel.deleteRecordsFromCoreData()
                viewModel.gachaList.removeAll()
                viewModel.uiPart = .NoData
            }, label: { Text("gacha.home.menu.delete_ok") })
        }, message: { Text("gacha.home.menu.delete_p") })
    }
    
    var Content: some View {
        let character = viewModel.gachaList
            .filter { $0.gachaType == viewModel.characterGacha || $0.gachaType == "400" }
            .sorted(by: { Int($0.id!)! < Int($1.id!)! }) // 按照时间先后顺序原地排序（才发现这个id才是真正排序时的依据 用time代表的时间戳一定出事）
        let weapon = viewModel.gachaList
            .filter({ $0.gachaType == viewModel.weaponGacha }).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        let resident = viewModel.gachaList
            .filter({ $0.gachaType == viewModel.residentGacha }).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        let collection = viewModel.gachaList
            .filter({ $0.gachaType == viewModel.collectionGacha }).sorted(by: { Int($0.id!)! < Int($1.id!)! })
        return TabView(selection: $gachaPart) {
            ScrollView {
                ScrollView(.horizontal, content: {
                    HStack(alignment: .top, spacing: 8) {
                        GachaBulletin(specificData: character, gachaTitle: "gacha.home.avatar")
                        GachaBulletin(specificData: weapon, gachaTitle: "gacha.home.weapon")
                        GachaBulletin(specificData: resident, gachaTitle: "gacha.home.resident")
                        GachaBulletin(specificData: collection, gachaTitle: "gacha.home.collection")
                    }
                }).padding(.horizontal, 4)
            }.tabItem({ Text("gacha.home.tab_overview") }).tag(GachaPart.Overview)
        }
    }
    
    var NoDataPart: some View {
        return VStack {
            Image("expecting_new_world").resizable().scaledToFit().frame(width: 72, height: 72)
            Text("gacha.no_data.title").font(.title2).bold().padding(.top, 8)
            MDLikeTile(leadingIcon: "externaldrive.badge.icloud", endIcon: "arrow.forward", title: "gacha.no_data.cloud", onClick: {
                GlobalUIModel.exported.makeALoading(msg: "我们正在获取数据，请确保全程网络通畅。")
                Task {
                    await viewModel.updateDataFromCloud()
                }
            })
            MDLikeTile(leadingIcon: "square.and.arrow.down", endIcon: "arrow.forward", title: "gacha.no_data.file", onClick: {
                let openPanel = NSOpenPanel()
                openPanel.allowedContentTypes = [.json]; openPanel.allowsMultipleSelection = false
                openPanel.message = NSLocalizedString("gacha.home.menu.update_p2", comment: "")
                openPanel.begin { result in
                    if result == NSApplication.ModalResponse.OK {
                        if let url = openPanel.url {
                            viewModel.updateDataFromFile(url: url)
                        }
                    }
                }
            })
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
        .frame(maxWidth: 400)
    }
    
    enum GachaPart {
        case Overview
    }
}
