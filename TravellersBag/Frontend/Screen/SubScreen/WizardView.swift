//
//  WizardView.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/15.
//

import SwiftUI

struct WizardView: View {
    enum WizardViewPart {
        case Hello; case Downloader
    }
    
    @State private var uiPart: WizardViewPart = .Hello
    let changeAppState: () -> Void
    
    var body: some View {
        NavigationStack {
            switch uiPart {
            case .Hello:
                WizardHello(nextPage: {
                    withAnimation(.smooth, {
                        uiPart = .Downloader
                    })
                }).padding()
            case .Downloader:
                WizardDownload(
                    changeAppState: changeAppState
                ).padding()
            }
        }
    }
}

extension WizardView {
    struct WizardDownload: View {
        @State private var currentCount: Double = 0
        @State private var total: Double = 1
        @State private var showError: Bool = false
        @State private var errMsg: String = ""
        let changeAppState: () -> Void
        
        var body: some View {
            VStack {
                Image(systemName: "square.and.arrow.down.on.square").resizable().controlSize(.large)
                    .frame(width: 72, height: 72)
                Text("wizard.download.title").font(.largeTitle.bold())
                Text("wizard.download.exp").font(.callout).foregroundStyle(.secondary)
                ZStack {}.padding(.vertical, 32)
                ProgressView(value: currentCount / total, total: 1.0)
                HStack {
                    Text("wizard.download.tip").font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                }
                Button("wizard.download", action: {
                    Task.detached {
                        do {
                            try await StaticResource.downloadStaticResource { cur, tot in
                                await MainActor.run {
                                    currentCount = Double(cur)
                                    total = Double(tot)
                                }
                            }
                            await MainActor.run {
                                changeAppState()
                            }
                        } catch {
                            await MainActor.run {
                                errMsg = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                }).buttonStyle(.borderedProminent)
            }
            .alert(errMsg, isPresented: $showError, actions: {})
        }
    }
}

extension WizardView {
    struct WizardHello: View {
        let nextPage: () -> Void
        @State private var usaStatus: Bool = false
        @State private var oslStatus: Bool = false
        
        var body: some View {
            VStack {
                Image("app_logo")
                    .resizable()
                    .controlSize(.large)
                    .frame(width: 92, height: 92)
                Text("wizard.hello.title").font(.largeTitle.bold())
                Text("wizard.hello.exp").font(.callout).foregroundStyle(.secondary)
                ZStack {}.padding(.vertical, 32)
                Toggle(isOn: $usaStatus, label: { Link("wizard.label.usa", destination: URL(string: "https://baidu.com")!).padding(.leading) })
                Toggle(isOn: $oslStatus, label: { Link("wizard.label.osl", destination: URL(string: "https://baidu.com")!).padding(.leading) })
                Image(systemName: "hand.raised.app")
                    .resizable()
                    .controlSize(.large).foregroundStyle(.accent)
                    .frame(width: 16, height: 16)
                Text("wizard.hello.privacy").font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button("wizard.start", action: {
                    if usaStatus && oslStatus {
                        nextPage()
                    }
                }).buttonStyle(.borderedProminent)
            }
        }
    }
}
