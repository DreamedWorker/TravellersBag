//
//  WizardScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/3/4.
//

import SwiftUI

struct WizardScreen: View {
    
    @State private var uiPart: WizardScreenPart = .DefaultPane
    
    @ViewBuilder
    var body: some View {
        switch uiPart {
        case .DefaultPane:
            WizardFirstScreen(
                goNext: { uiPart = .ResourcePane }
            )
        case .ResourcePane:
            WizardResourceScreen()
        }
    }
    
    enum WizardScreenPart {
        case DefaultPane
        case ResourcePane
    }
}

struct WizardFirstScreen: View {
    private var goNext: () -> Void
    
    init(goNext: @escaping () -> Void) {
        self.goNext = goNext
    }
    
    var body: some View {
        VStack {
            Image("app_logo")
                .resizable()
                .scaledToFit()
                .frame(height: 72)
            Text("wizard.hello.title")
                .font(.title).bold()
            Text("wizard.hello.exp")
                .multilineTextAlignment(.center)
                .padding(.top, 4).padding(.bottom)
            FeatureCard(iconName: "newspaper", titleKey: "wizard.hello.announce", contextKey: "wizard.hello.announceMore")
                .padding(4)
            FeatureCard(iconName: "note.text", titleKey: "wizard.hello.plan", contextKey: "wizard.hello.planMore")
                .padding(4)
            FeatureCard(iconName: "gamecontroller", titleKey: "wizard.hello.game", contextKey: "wizard.hello.gameMore")
                .padding(4)
            Spacer()
            Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                .resizable()
                .symbolRenderingMode(.multicolor)
                .foregroundStyle(.accent)
                .frame(width: 18, height: 18)
            Text("wizard.hello.privacy")
                .foregroundStyle(.secondary)
                .font(.footnote)
                .multilineTextAlignment(.center)
            Spacer()
            HStack {
                Spacer()
                StyleButton(
                    label: "wizard.hello.continue",
                    action: goNext,
                    color: true
                )
            }
        }
        .padding(20)
        .frame(width: 450)
    }
}

struct WizardResourceScreen: View {
    @StateObject private var vm = WizardResViewModel()
    
    private func finishAndRelaunch() {
        PreferenceMgr.default.setValue(key: PreferenceMgr.lastUsedAppVersion, val: "0.1.0")
        NSApplication.shared.terminate(self)
    }
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.bubble.circle.fill")
                    .resizable()
                    .symbolRenderingMode(.multicolor)
                    .foregroundStyle(.accent)
                    .frame(width: 24, height: 24)
                VStack(alignment: .leading) {
                    Text("wizard.res.noticeTitle")
                        .font(.callout)
                        .bold()
                    Text("wizard.res.noticeMsg")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.background.shadow(.drop(radius: 2))))
            HStack(alignment: .top) {
                VStack {
                    HStack {
                        Text("wizard.res.txt.title")
                            .bold()
                        Spacer()
                    }
                    Text("wizard.res.txt.more")
                        .font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                    Image("wizard_bg")
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Spacer()
                    HStack {
                        Spacer()
                        StyleButton(
                            label: "wizard.res.txt.download",
                            action: {
                                vm.showJsonDownloading = true
                                Task {
                                    switch await vm.downloadTextRes() {
                                    case .success(_):
                                        DispatchQueue.main.async {
                                            vm.showJsonDownloading = false
                                            vm.alertMate.showAlert(
                                                msg: NSLocalizedString("wizard.res.info.jsonDownloadFinished", comment: ""),
                                                type: .Info
                                            )
                                        }
                                    case .failure(let failure):
                                        DispatchQueue.main.async {
                                            vm.showJsonDownloading = false
                                            vm.alertMate.showAlert(
                                                msg: String.localizedStringWithFormat(
                                                    NSLocalizedString("wizard.res.error.jsonDownload", comment: ""),
                                                    failure.localizedDescription),
                                                type: .Error
                                            )
                                        }
                                    }
                                }
                            },
                            color: true)
                    }
                    Text("wizard.res.txt.version")
                        .font(.footnote).foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.background.shadow(.drop(radius: 2))))
                VStack {
                    HStack {
                        Text("wizard.res.img.title")
                            .bold()
                        Spacer()
                    }
                    Text("wizard.res.img.exp")
                        .font(.footnote).foregroundStyle(.secondary)
                    List {
                        ForEach(vm.imagesDownloadList, id: \.self) { single in
                            HStack {
                                Label(single, systemImage: "photo.stack")
                                Spacer()
                                Button(
                                    "wizard.res.txt.get",
                                    action: {
                                        vm.showImageDownloading = true
                                        vm.startDownload(url: single)
                                    }
                                )
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .listRowSeparator(.hidden)
                            .padding(4)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(content: { RoundedRectangle(cornerRadius: 4).stroke(.secondary, lineWidth: 1) })
                        }
                    }
                }
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.background.shadow(.drop(radius: 2))))
            }
            .padding(.vertical, 16)
            Spacer()
            Image(systemName: "info.circle")
                .foregroundStyle(.accent)
                .frame(width: 24, height: 24)
            Text("wizard.res.source")
                .font(.footnote).foregroundStyle(.secondary)
            HStack {
                Spacer()
                StyleButton(
                    label: "wizard.res.finish",
                    action: finishAndRelaunch,
                    color: true
                )
            }
        }
        .padding(20)
        .alert(vm.alertMate.title, isPresented: $vm.alertMate.showIt, actions: {}, message: { Text(verbatim: vm.alertMate.msg) })
        .sheet(isPresented: $vm.showJsonDownloading, content: { JsonDownloadSheet })
        .sheet(isPresented: $vm.showImageDownloading, content: { ImageDownloadSheet })
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 {
                    return nil
                } else {
                    return event
                }
            }
        }
    }
    
    private var JsonDownloadSheet: some View {
        return NavigationStack {
            ProgressView()
            Text("wizard.res.sheetJsonTitle").font(.title).bold().padding(.bottom, 4)
            Text(
                String.localizedStringWithFormat(
                    NSLocalizedString("wizard.res.sheetJsonStatus", comment: ""),
                    String(vm.staticJsonCount), String(vm.finalCount)
                )
            )
        }
        .padding(20)
    }
    
    private var ImageDownloadSheet: some View {
        return NavigationStack {
            Text("wizard.res.sheetImageTitle").font(.title).bold().padding(.bottom, 4)
            ProgressView(value: vm.downloadProgress, total: 1.0)
        }
        .padding(20)
        .frame(maxWidth: 300)
    }
}

#Preview {
    WizardResourceScreen()
}
