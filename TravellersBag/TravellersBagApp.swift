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

@main
struct TravellersBagApp: App {
    private let updaterController: SPUStandardUpdaterController
    @State private var showFPError: Bool = false
    @State var showHutaoPassport: Bool = false
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            if checkCrtVer() {
                ContentView()
                    .onAppear { // 生成除设备指纹外的uuid信息
                        TBDeviceKit.checkEnvironment()
                        Task { await updateDeviceFigerprint() }
                    }
                    .modelContainer(for: [MihoyoAccount.self, HutaoPassport.self, GachaItem.self])
                    .alert("def.error.updateFP", isPresented: $showFPError, actions: {})
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
