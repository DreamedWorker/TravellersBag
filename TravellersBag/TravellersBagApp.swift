//
//  TravellersBagApp.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/12/17.
//

import SwiftUI
import Sparkle

@main
struct TravellersBagApp: App {
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            if checkCrtVer() {
                ContentView()
                    .onAppear { // 生成除设备指纹外的uuid信息
                        TBDeviceKit.checkEnvironment()
                    }
            } else {
                WizardView()
            }
        }
        .commands {
            CommandGroup(after: .appInfo, addition: { CheckForUpdatesView(updater: updaterController.updater) })
        }
    }
    
    private func checkCrtVer() -> Bool {
        let version = UserDefaults.standard.string(forKey: "lastUsedVersion") ?? "0.0.0"
        return version == "0.0.3"
    }
}
