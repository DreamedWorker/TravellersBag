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
    let navigator: (Int) -> Void
    @State private var name: String = ""
    @State private var useBundleAlert: Bool = false
    
    var DownloadStateSheet: some View {
        return NavigationStack {
            Text("wizard.resource.imageGo").font(.title).bold().padding(.bottom, 8)
            Text(String.localizedStringWithFormat(NSLocalizedString("wizard.resource.imageGoP", comment: ""), name))
            ProgressView(value: model.uiState.downloadState, total: 1.0)
        }
        .padding()
        .frame(maxWidth: 300)
        .toolbar {
            ToolbarItem(placement: .cancellationAction, content: {
                Button("app.cancel", action: {
                    model.cancelDownload()
                    model.uiState.showDownloadSheet = false
                })
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
                                model.uiState.downloadName = imageName
                                model.uiState.showDownloadSheet = true
                                model.startDownload(
                                    url: "https://static-zip.snapgenshin.cn/\(imageName).zip",
                                    beforeDownload: {
                                        model.checkBeforeDownload(url: "https://static-zip.snapgenshin.cn/\(imageName).zip")
                                    })
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
                Button(action: {}, label: { Text("wizard.resource.useBuiltIn").padding(4) })
                Button("wizard.resource.useBuiltIn", action: { useBundleAlert = true }).buttonStyle(BorderedProminentButtonStyle())
                if model.uiState.canGoNext || UserDefaults.configGetConfig(forKey: "staticWizardDownloaded", def: false) {
                    Button("wizard.resource.next", action: { navigator(1) }).buttonStyle(BorderedProminentButtonStyle())
                }
            }
        }
        .onAppear {
            model.mkdir()
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
        .sheet(isPresented: $model.uiState.showDownloadSheet, content: { DownloadStateSheet })
        .alert(
            "wizard.resource.old", isPresented: $useBundleAlert,
            actions: {
                Button(role: .destructive, action: { navigator(3) }, label: { Text("wizard.resource.oldUse") })
            },
            message: { Text("wizard.resource.oldP") }
        )
    }
}

struct FinshSettings : View {
    var body: some View {
        ZStack {
            Image("wizard_bg").resizable()
            VStack {
                ZStack {}.frame(height: 150)
                Button("wizard.finished", action: {
                    UserDefaults.configSetValue(key: "currentAppVersion", data: "0.0.2")
                    NSApplication.shared.terminate(self)
                }).buttonStyle(BorderedProminentButtonStyle())
                Text("wizard.ok")
                    .foregroundColor(Color(red: 0.17, green: 0.59, blue: 0.47)).bold()
            }.frame(width: 300)
        }
    }
}
