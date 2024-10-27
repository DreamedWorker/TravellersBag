//
//  DeviceInfo.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2024/10/27.
//

import SwiftUI

struct DeviceInfo : View {
    @StateObject private var model = DeviceInfoModel()
    
    var body: some View {
        VStack {
            Image(systemName: "desktopcomputer").resizable().foregroundStyle(.accent).frame(width: 72, height: 72)
            Text("wizard.device.title").font(.title).bold().padding(.bottom, 4)
            Text("wizard.device.subtitle").font(.title3).multilineTextAlignment(.leading).padding(.bottom, 8)
            Form {
                HStack {
                    Text("wizard.device.id")
                    Spacer()
                    Text(model.uiState.deviceId).font(.callout).foregroundStyle(.secondary)
                }
                HStack {
                    Text("wizard.device.bbs")
                    Spacer()
                    Text(model.uiState.bbsDeviceId).font(.callout).foregroundStyle(.secondary)
                }
                VStack {
                    HStack {
                        Text("wizard.device.fp")
                        Spacer()
                        Text(model.uiState.deviceFp).font(.callout).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text((model.uiState.deviceFp.starts(with: "38d")) ? "wizard.device.fpVerified" : "wizard.device.fpVerifiedNot")
                            .foregroundStyle((model.uiState.deviceFp.starts(with: "38d")) ? .green : .red)
                            .font(.callout)
                        Spacer()
                        Button("wizard.device.fpGen", action: { Task { await model.generateDeviceFp() } })
                    }
                    Text("wizard.device.fpGenYaagl").font(.footnote).foregroundStyle(.secondary)
                }
            }.formStyle(.grouped).scrollDisabled(true)
            Spacer()
            HStack {
                if model.uiState.deviceFp.starts(with: "38d") || model.canGoNext {
                    Button("wizard.resource.next", action: {}).buttonStyle(BorderedProminentButtonStyle())
                }
            }
        }
        .padding()
        .alert(model.uiState.deviceFpInfo.errMsg, isPresented: $model.uiState.deviceFpInfo.showErrAlert, actions: {})
        .onAppear {
            TBCore.shared.checkEnvironment()
            model.refreshData()
        }
    }
}

private class DeviceInfoModel : ObservableObject {
    @Published var uiState = DeviceInfoData()
    @Published var canGoNext = false
    
    func refreshData() {
        uiState.deviceId = TBCore.shared.configGetConfig(forKey: TBCore.DEVICE_ID, def: "")
        uiState.bbsDeviceId = TBCore.shared.configGetConfig(forKey: TBCore.BBS_DEVICE_ID, def: "")
        uiState.deviceFp = TBCore.shared.configGetConfig(forKey: TBCore.DEVICE_FP, def: "")
    }
    
    func generateDeviceFp() async {
        do {
            let fp = try await TBCore.shared.updateDeviceFp()
            TBCore.shared.configSetValue(key: TBCore.DEVICE_FP, data: fp)
            TBCore.shared.configSetValue(key: "deviceFpLastUpdated", data: Int(Date().timeIntervalSince1970))
            DispatchQueue.main.async {
                self.refreshData()
                self.uiState.deviceFpInfo.makeAlert(msg: NSLocalizedString("wizard.device.fpGenOk", comment: ""))
                self.canGoNext = true
            }
        } catch {
            TBCore.shared.configSetValue(key: TBCore.DEVICE_FP, data: TBCore.shared.getLowerHexString(length: 13))
            DispatchQueue.main.async {
                self.refreshData()
                self.uiState.deviceFpInfo.makeAlert(msg: error.localizedDescription)
                self.canGoNext = true
            }
        }
    }
}
