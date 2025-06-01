//
//  GachaView.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/28.
//

import SwiftUI
import SwiftData

struct GachaView: View {
    @Environment(\.modelContext) private var operation
    @StateObject private var viewModel: GachaViewModel = .init()
    @State private var gachaItems: [GachaItem] = []
    @Query private var accounts: [HoyoAccount]
    @State private var selectedAccount: HoyoAccount? = nil
    @State private var showWaitingSheet: Bool = false
    @State private var fileDownloadState: Float = 0
    @State private var filename: String = ""
    
    var body: some View {
        if accounts.isEmpty {
            ContentUnavailableView("gacha.blocked.needAccount", systemImage: "hand.raised")
        } else {
            NavigationStack {
                if viewModel.uiState.gachaRecords.count > 0 {
                    if !viewModel.uiState.showLogic {
                        ScrollView(.horizontal, showsIndicators: false) {
                            let character = viewModel.uiState.gachaRecords
                                .filter { $0.gachaType == viewModel.characterGacha || $0.gachaType == "400" }
                                .sorted(by: { Int($0.id)! < Int($1.id)! })
                            let weapon = viewModel.uiState.gachaRecords
                                .filter({ $0.gachaType == viewModel.weaponGacha }).sorted(by: { Int($0.id)! < Int($1.id)! })
                            let resident = viewModel.uiState.gachaRecords
                                .filter({ $0.gachaType == viewModel.residentGacha }).sorted(by: { Int($0.id)! < Int($1.id)! })
                            let collection = viewModel.uiState.gachaRecords
                                .filter({ $0.gachaType == viewModel.collectionGacha }).sorted(by: { Int($0.id)! < Int($1.id)! })
                            let history = viewModel.getGachaEvents()
                            LazyHStack(alignment: .top) {
                                GachaBulletin(specificData: character, gachaTitle: "gacha.home.avatar", event: history, showUp: true)
                                    .padding(.vertical, 8).padding(.horizontal, 4)
                                GachaBulletin(specificData: weapon, gachaTitle: "gacha.home.weapon", event: history, showUp: true)
                                    .padding(.vertical, 8).padding(.trailing, 4)
                                GachaBulletin(specificData: resident, gachaTitle: "gacha.home.resident", event: history)
                                    .padding(.vertical, 8)
                                GachaBulletin(specificData: collection, gachaTitle: "gacha.home.collection", event: history)
                                    .padding(.vertical, 8).padding(.horizontal, 4)
                            }
                        }
                    } else {
                        Image(systemName: "storefront")
                            .resizable().foregroundStyle(.accent)
                            .frame(width: 72, height: 72)
                        Text("gacha.image.title").font(.title.bold())
                        Button("gacha.image.download", action: {
                            viewModel.uiState.showImageSheet = true
                        }).buttonStyle(.borderedProminent)
                        Button("gacha.image.forceEntrance", action: {
                            viewModel.uiState.showImageSheet = false
                            viewModel.uiState.showLogic = true
                        })
                    }
                } else {
                    Image(systemName: "tray")
                        .resizable().foregroundStyle(.accent)
                        .frame(width: 72, height: 72)
                    Text("gacha.empty.title").font(.title.bold())
                    Button(
                        action: {
                            startSync()
                        },
                        label: {
                            Label("gacha.action.sync", systemImage: "square.and.arrow.down.fill").padding()
                        }
                    ).buttonStyle(.borderedProminent)
                }
            }
            .onAppear {
                selectedAccount = accounts.filter({ $0.activedAccount }).first!
                viewModel.queryRecords(accounts.filter({ $0.activedAccount }).first!, context: operation)
                viewModel.checkImageResources()
            }
            .toolbar {
                ToolbarItem {
                    Button(
                        action: { startSync() },
                        label: { Image(systemName: "arrow.2.circlepath.circle").help("gacha.action.sync") }
                    )
                }
                ToolbarItem {
                    Button(
                        action: {
                            viewModel.uiState.showLogic = false
                            viewModel.uiState.showImageSheet = true
                        },
                        label: { Image(systemName: "photo.stack").help("gacha.action.downloadImg") }
                    )
                }
                ToolbarItem {
                    Button(
                        action: {
                            Task {
                                let panel = NSOpenPanel()
                                panel.canCreateDirectories = true
                                panel.canChooseFiles = false
                                panel.canChooseDirectories = true
                                panel.message = NSLocalizedString("gacha.panel.saveTitle", comment: "")
                                await panel.begin()
                                if let url = panel.url {
                                    do {
                                        try UIGFStandard.exportGachaRecords(
                                            account: selectedAccount!.game.genshinUID, targetFolder: url, context: operation
                                        )
                                        DispatchQueue.main.async {
                                            self.viewModel.uiState.alertMate.showAlert(msg: NSLocalizedString("app.done", comment: ""))
                                        }
                                    } catch {
                                        DispatchQueue.main.async {
                                            self.viewModel.uiState.alertMate.showAlert(
                                                msg: String.localizedStringWithFormat(
                                                    NSLocalizedString("gacha.panel.error.export", comment: ""),
                                                    error.localizedDescription
                                                ),
                                                type: .Error
                                            )
                                        }
                                    }
                                }
                            }
                        },
                        label: { Image(systemName: "square.and.arrow.up").help("gacha.action.exportRecords") }
                    )
                }
            }
            .sheet(isPresented: $showWaitingSheet, content: { WaitingSheet })
            .alert(
                viewModel.uiState.alertMate.title,
                isPresented: $viewModel.uiState.alertMate.showIt,
                actions: {},
                message: { Text(viewModel.uiState.alertMate.msg) }
            )
            .sheet(isPresented: $viewModel.uiState.showImageSheet, content: {
                NavigationStack {
                    Text("gacha.image.sheet.title")
                        .font(.title.bold())
                        .padding(.bottom, 8)
                    ProgressView(value: fileDownloadState, total: 1.0)
                        .progressViewStyle(.linear)
                        .padding()
                    HStack {
                        Text(String.localizedStringWithFormat(NSLocalizedString("gacha.image.sheet.current", comment: ""), filename))
                        Spacer()
                    }
                    Text("gacha.image.sheet.tip").font(.footnote).foregroundStyle(.secondary)
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction, content: {
                        Button("gacha.image.sheet.retry", action: {
                            Task.detached {
                                await viewModel.downloader.pause()
                                try! await Task.sleep(for: .seconds(3))
                                await viewModel.downloader.resume()
                            }
                        })
                    })
                    ToolbarItem(placement: .destructiveAction, content: {
                        Button("app.cancel", action: {
                            viewModel.downloader.cancel()
                            viewModel.uiState.showImageSheet = false
                        })
                    })
                }
                .onAppear {
                    var urls: [URL] = []
                    PicResource.imagesDownloadList.forEach { single in
                        urls.append(URL(string: "https://api.snapgenshin.com/static/zip/\(single).zip")!)
                    }
                    Task.detached {
                        await viewModel.downloader.startDownload(
                            urls: urls,
                            progressHandler: { url, progress in
                                DispatchQueue.main.async {
                                    self.fileDownloadState = Float(progress)
                                    self.filename = url.lastPathComponent
                                }
                            },
                            completion: { result in
                                switch result {
                                case .success(_):
                                    DispatchQueue.main.async {
                                        self.viewModel.uiState.showImageSheet = false
                                        self.viewModel.checkImageResources()
                                    }
                                case .failure(let failure):
                                    DispatchQueue.main.async {
                                        self.viewModel.uiState.showImageSheet = false
                                        self.viewModel.uiState.alertMate.showAlert(msg: "下载失败：\(failure.localizedDescription)", type: .Error)
                                    }
                                }
                            }
                        )
                    }
                }
            })
        }
    }
    
    private func startSync() {
        showWaitingSheet = true
        Task.detached {
            await viewModel.updateDataFromCloud(
                selectedAccount!,
                originalList: viewModel.uiState.gachaRecords,
                onWrite: { item in
                    await MainActor.run {
                        operation.insert(item)
                    }
                },
                onFailed: {
                    DispatchQueue.main.async {
                        self.showWaitingSheet = false
                    }
                },
                onFinished: { msg, acc in
                    await MainActor.run {
                        showWaitingSheet = false
                        viewModel.uiState.alertMate.showAlert(msg: msg)
                        viewModel.queryRecords(acc, context: operation)
                    }
                }
            )
        }
    }
    
    private var WaitingSheet: some View {
        return NavigationStack {
            Text("gacha.def.title").font(.title.bold())
            ProgressView().progressViewStyle(LinearProgressViewStyle())
            Text("gacha.def.waiting")
                .multilineTextAlignment(.center)
                .font(.callout).foregroundStyle(.secondary)
        }
        .padding()
    }
}
