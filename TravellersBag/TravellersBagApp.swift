//
//  TravellersBagApp.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/1.
//

import SwiftUI
import Sparkle
import SwiftData

let groupName = "NV65B8VFUD.travellersbag"

/// 应用数据库
let tbDatabase = try! ModelContainer(
    for: MihoyoAccount.self, HutaoPassport.self
)

@MainActor func getDefaultAccount() -> MihoyoAccount? {
    let fetch = FetchDescriptor<MihoyoAccount>(predicate: #Predicate { $0.active == true })
    return try? tbDatabase.mainContext.fetch(fetch).first
}

@main
struct TravellersBagApp: App {
    private var needWizard: Bool = false
    private let updaterController: SPUStandardUpdaterController
    @State var showHutaoPassport: Bool = false
    
    init() {
        needWizard = UserDefaults.configGetConfig(forKey: "currentAppVersion", def: "0.0.0") != "0.0.2"
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(needShowWizard: needWizard)
                .onAppear {
                    appPresetSettings()
                }
                .sheet(isPresented: $showHutaoPassport, content: { HutaoLogin(
                    dismiss: { showHutaoPassport = false }
                ) })
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdate(updater: updaterController.updater)
            }
            CommandGroup(replacing: .newItem, addition: {}) // 移除「文件」命令组 因为没有必要
        }
        .commands(content: {
            CommandMenu("app.command.title", content: {
                Button("app.command.hutao", action: {
                    showHutaoPassport = true
                }).keyboardShortcut(.init("h"), modifiers: .shift)
            })
        })
        Settings {
            SettingsPane().frame(maxWidth: 600)
        }
    }
}
