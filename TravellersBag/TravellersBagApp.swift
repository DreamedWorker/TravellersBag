//
//  TravellersBagApp.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/12/17.
//

import SwiftUI
import Sparkle
import SwiftData
import SwiftyJSON
import WidgetKit
import Sentry

@main
struct TravellersBagApp: App {
    private let updaterController: SPUStandardUpdaterController
    @State private var showFPError: Bool = false
    @State var showHutaoPassport: Bool = false
    @State var showAbout: Bool = false
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        SentrySDK.start { options in
            options.dsn = "https://94ef38f68876d3a718cf007d6fbb46e1@o4507083124834304.ingest.de.sentry.io/4507887457337424"
            options.debug = false
            options.tracesSampleRate = 1.0
            options.profilesSampleRate = 1.0
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if checkCrtVer() {
                ContentView()
                    .onAppear { // 生成除设备指纹外的uuid信息
                        TBDeviceKit.checkEnvironment()
                        Task { await updateDeviceFigerprint() }
                    }
                    .modelContainer(for: [MihoyoAccount.self, HutaoPassport.self, GachaItem.self, AchieveItem.self, AchieveArchive.self])
                    .alert("def.error.updateFP", isPresented: $showFPError, actions: {})
                    .sheet(isPresented: $showAbout, content: { AboutSheet(dismiss: { showAbout = false}) })
            } else {
                WizardView()
                    .sheet(isPresented: $showAbout, content: { AboutSheet(dismiss: { showAbout = false}) })
            }
        }
        .commands {
            CommandGroup(replacing: .appInfo, addition: { Button("def.about", action: { showAbout = true }) })
            CommandGroup(after: .appInfo, addition: { CheckForUpdatesView(updater: updaterController.updater) })
        }
        .commands {
            CommandMenu("command.title", content: {
                Button("command.content.updateWidget", action: { WidgetCenter.shared.reloadAllTimelines() })
            })
        }
        Settings { SettingsView() }
    }
    
    private func checkCrtVer() -> Bool {
        let version = UserDefaults.standard.string(forKey: "lastUsedVersion") ?? "0.0.0"
        return version == "0.0.3"
    }
    
    @MainActor private func updateDeviceFigerprint() async {
        let currentTime = Int(Date().timeIntervalSince1970)
        let lastUpdateTime = UserDefaults.standard.integer(forKey: "deviceFpLastUpdated")
        if currentTime - lastUpdateTime >= 432000 {
            do {
                let newFp = try await TBDeviceKit.updateDeviceFp()
                UserDefaults.standard.set(currentTime, forKey: "deviceFpLastUpdated")
                UserDefaults.standard.set(newFp, forKey: TBData.DEVICE_FP)
            } catch {
                DispatchQueue.main.async {
                    self.showFPError = true
                }
            }
        }
    }
}
