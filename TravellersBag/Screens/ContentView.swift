//
//  ContentView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/3/2.
//

import SwiftUI

struct ContentView: View {
    @State  // 上次使用的软件版本
    private var storedVersion = PreferenceMgr.default.getValue(key: PreferenceMgr.lastUsedAppVersion, def: "0.0.0")
    @State private var showFPError: Bool = false
    
    @ViewBuilder
    var body: some View {
        switch storedVersion {
        case "0.0.0":
            WizardScreen()
        default:
            if storedVersion == "0.1.0" {
                HomeStageScreen()
                    .alert("def.error.updateFP", isPresented: $showFPError, actions: {})
                    .onAppear {
                        FakeDeviceEnv.checkEnvironment()
                        Task { await updateDeviceFigerprint() }
                    }
            } else {
                WizardFirstScreen(goNext: {
                    PreferenceMgr.default.setValue(key: PreferenceMgr.lastUsedAppVersion, val: "0.1.0")
                    storedVersion = PreferenceMgr.default.getValue(key: PreferenceMgr.lastUsedAppVersion, def: "0.0.0")
                })
            }
        }
    }
    
    private func updateDeviceFigerprint() async {
        let currentTime = Int(Date().timeIntervalSince1970)
        let lastUpdateTime = PreferenceMgr.default.getValue(key: "deviceFpLastUpdated", def: 0)
        if currentTime - lastUpdateTime >= 432000 {
            do {
                let newFp = try await FakeDeviceEnv.updateDeviceFp()
                PreferenceMgr.default.setValue(key: "deviceFpLastUpdated", val: currentTime)
                PreferenceMgr.default.setValue(key: TBData.DEVICE_FP, val: newFp)
            } catch {
                DispatchQueue.main.async {
                    self.showFPError = true
                }
            }
        }
    }
}
