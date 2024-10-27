//
//  WizardFuncUnits.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/24.
//

import SwiftUI
import AlertToast

struct ResourceDownload : View {
    @StateObject private var model = WizardResourceModel()
    @State private var downloadState: Float = 0
    let navigator: (Int) -> Void
    @State private var showDownloadSheet: Bool = false
    @State private var dm: TBDownloadManager? = nil
    @State private var name: String = ""
    
    var DownloadStateSheet: some View {
        return NavigationStack {
            Text("wizard.resource.imageGo").font(.title).bold().padding(.bottom, 8)
            Text(String.localizedStringWithFormat(NSLocalizedString("wizard.resource.imageGoP", comment: ""), name))
            ProgressView(value: downloadState, total: 1.0)
        }
        .padding()
        .frame(maxWidth: 300)
        .toolbar {
            ToolbarItem(placement: .cancellationAction, content: {
                Button("app.cancel", action: {
                    dm?.cancelDownload(relative: { showDownloadSheet = false; downloadState = 0; name = "" }) }
                )
            })
        }
    }
    
    var body: some View {
        ScrollView {
            Image(systemName: "square.and.arrow.down.on.square.fill").resizable().foregroundStyle(.accent).frame(width: 72, height: 72)
            Text("wizard.resource.title").font(.title).bold().padding(.bottom, 4)
            Text("wizard.resource.subtitle").font(.title3).padding(.bottom, 16)
            VStack {
                HStack(spacing: 8, content: {
                    Image(systemName: "star.square.on.square.fill").font(.title3)
                    Text("wizard.resource.staticTitle").font(.title3).bold()
                    Spacer()
                })
                Text("wizard.resource.staticExplanation").multilineTextAlignment(.leading)
                HStack {
                    Spacer()
                    Button("wizard.resource.download", action: {
                        model.uiState.showJsonDownload = true
                        Task { await model.downloadStaticJsonResource() }
                    }).disabled(!model.showDownloadBtn)
                    Button("wizard.resource.staticIndex", action: {
                        model.indexAvatars()
                    }).disabled(!model.canIndex)
                }
                Text("wizard.resource.staticSource").font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
            VStack {
                HStack(spacing: 8, content: {
                    Image(systemName: "photo.artframe").font(.title3)
                    Text("wizard.resource.imageTitle").font(.title3).bold()
                    Spacer()
                    Text("wizard.resource.imageSee").font(.footnote).foregroundStyle(.secondary)
                })
                List {
                    ForEach(model.imagesDownloadList, id: \.self) { imageName in
                        HStack {
                            Text(imageName)
                            Spacer()
                            Button("wizard.resource.download", action: {
                                name = imageName
                                let url = "https://static-zip.snapgenshin.cn/\(imageName).zip"
                                dm!.startDownload(
                                    url: url,
                                    beforeDownload: {
                                        showDownloadSheet = true
                                        model.checkBeforeDownload(url: url)
                                    }
                                )
                            })
                        }
                    }
                }.frame(height: 70)
                Text("wizard.resource.staticSource").font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
            Spacer()
            HStack(spacing: 16) {
                Button("wizard.resource.useBuiltIn", action: { navigator(3) }).buttonStyle(BorderedProminentButtonStyle())
                if model.uiState.canGoNext || TBCore.shared.configGetConfig(forKey: "staticWizardDownloaded", def: false) {
                    Button("wizard.resource.next", action: { navigator(1) }).buttonStyle(BorderedProminentButtonStyle())
                }
            }
        }
        .onAppear {
            model.mkdir()
            dm = TBDownloadManager(
                postDownload: { file in
                    model.postDownloadEvent(url: file, name: name, dismiss: { downloadState = 0; showDownloadSheet = false } )
                },
                onDownload: { state in
                    DispatchQueue.main.async {
                        self.downloadState = state
                    }
                }
            )
            Task {
                do {
                    try await model.fetchMetaFile()
                } catch {}
            }
        }
        .toast(
            isPresenting: $model.uiState.showJsonDownload,
            alert: {
                AlertToast(
                    displayMode: .alert, type: .loading,
                    title: String.localizedStringWithFormat(
                        NSLocalizedString(
                            "wizard.resource.staticWait", comment: ""),
                        String(model.staticJsonCount), String(model.uiState.jsonList.count)
                    )
                )
            }
        )
        .toast(isPresenting: $model.uiState.fatalAlert, alert: { AlertToast(type: .error(.red), title: model.uiState.fatalMsg) })
        .alert("wizard.resource.downloadJsonOK", isPresented: $model.uiState.successfulAlert, actions: {})
        .sheet(isPresented: $showDownloadSheet, content: { DownloadStateSheet })
    }
}

struct FinshSettings : View {
    var body: some View {
        ZStack {
            Image("wizard_bg").resizable()
            VStack {
                Text("wizard.ok").foregroundStyle(.white).frame(maxWidth: 300).padding().multilineTextAlignment(.center)
                Spacer()
            }
        }
    }
}
