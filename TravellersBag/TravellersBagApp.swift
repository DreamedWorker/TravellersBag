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
                    let lastLogin = UserDefaults.configGetConfig(forKey: "hutaoLastLogin", def: 0)
                    let current = Int(Date().timeIntervalSince1970)
                    if current - lastLogin >= 7200 {
                        if UserDefaults.configGetConfig(forKey: "use_key_chain", def: false) {
                            Task {
                                if let account = try? TBHutaoService.read4keychain(
                                    username: UserDefaults.configGetConfig(forKey: "keychain_name", def: "")) {
                                    let result = try? await TBHutaoService.loginPassport(username: account.username, password: account.password)
                                    if let surely = result {
                                        let query = FetchDescriptor<HutaoPassport>()
                                        let account = try? tbDatabase.mainContext.fetch(query).first
                                        if let ht = account {
                                            ht.auth = surely["data"].stringValue
                                            try! TBDatabaseOperation.saveAfterChanges()
                                            UserDefaults.configSetValue(key: "hutaoLastLogin", data: current)
                                        }
                                    }
                                    DispatchQueue.main.async {
                                        self.showHutaoPassport = true
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        self.showHutaoPassport = true
                                    }
                                }
                            }
                        } else {
                            showHutaoPassport = true
                        }
                    } else {
                        showHutaoPassport = true
                    }
                }).keyboardShortcut(.init("h"), modifiers: .shift)
            })
        })
        Settings {
            SettingsPane().frame(maxWidth: 600)
        }
    }
}
