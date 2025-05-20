//
//  SettingsPane.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/17.
//

import SwiftUI

struct SettingsPane: View {
    
    @State private var selection: SettingsPart = .general
    
    @ViewBuilder
    var body: some View {
        TabView(selection: $selection) {
            Generatic().tabItem({ Label("settings.tab.gear", systemImage: "gearshape") }).tag(SettingsPart.general)
        }
        .padding(20)
    }
    
    enum SettingsPart: Hashable {
        case general
    }
}

extension SettingsPane {
    struct Generatic: View {
        @State private var currentCount: Double = 0
        @State private var total: Double = 1
        @State private var showError: Bool = false
        @State private var showDialog: Bool = false
        @State private var errMsg: String = ""
        
        var body: some View {
            NavigationStack {
                VStack {
                    HStack {
                        Text("settings.gear.label.updateStatic")
                        Spacer()
                        Button("settings.gear.action.updateStatic", action: {
                            showDialog = true
                        })
                    }
                    HStack {
                        Text("settings.gear.tip.updateStatic").font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                        Spacer()
                    }
                }
                Spacer()
            }
            .padding(20)
            .alert(errMsg, isPresented: $showError, actions: {})
            .sheet(isPresented: $showDialog, content: {
                NavigationStack {
                    ProgressView(value: currentCount / total, total: 1.0)
                    HStack {
                        Text("wizard.download.tip").font(.footnote).foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                .padding()
                .onAppear {
                    Task.detached {
                        do {
                            try await StaticResource.downloadStaticResource { cur, tot in
                                await MainActor.run {
                                    currentCount = Double(cur)
                                    total = Double(tot)
                                }
                            }
                            await MainActor.run {
                                showDialog = false
                            }
                        } catch {
                            await MainActor.run {
                                errMsg = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                }
            })
        }
    }
}
