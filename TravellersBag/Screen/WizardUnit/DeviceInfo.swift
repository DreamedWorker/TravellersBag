//
//  DeviceInfo.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2024/10/27.
//

import SwiftUI

struct DeviceInfo : View {
    @StateObject private var model = DeviceInfoModel()
    let navigator: () -> Void
    
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
                    Button(action: { navigator() }, label: { Text("wizard.resource.next").padding(4) })
                        .buttonStyle(BorderedProminentButtonStyle())
                }
            }
        }
        .padding()
        .alert(model.uiState.deviceFpInfo.errMsg, isPresented: $model.uiState.deviceFpInfo.showErrAlert, actions: {})
        .onAppear {
            ModifiedConfigHelper.checkEnvironment()
            model.refreshData()
        }
    }
}

private class DeviceInfoModel : ObservableObject {
    @Published var uiState = DeviceInfoData()
    @Published var canGoNext = false
    
    func refreshData() {
        uiState.deviceId = UserDefaults.configGetConfig(forKey: TBConfigKeys.DEVICE_ID, def: "")
        uiState.bbsDeviceId = UserDefaults.configGetConfig(forKey: TBConfigKeys.BBS_DEVICE_ID, def: "")
        uiState.deviceFp = UserDefaults.configGetConfig(forKey: TBConfigKeys.DEVICE_FP, def: "")
    }
    
    func generateDeviceFp() async {
        do {
            let fp = try await ModifiedConfigHelper.updateDeviceFp()
            UserDefaults.configSetValue(key: TBConfigKeys.DEVICE_FP, data: fp)
            UserDefaults.configSetValue(key: "deviceFpLastUpdated", data: Int(Date().timeIntervalSince1970))
            DispatchQueue.main.async {
                self.refreshData()
                self.uiState.deviceFpInfo.makeAlert(msg: NSLocalizedString("wizard.device.fpGenOk", comment: ""))
                self.canGoNext = true
            }
        } catch {
            UserDefaults.configSetValue(key: TBConfigKeys.DEVICE_FP, data: ModifiedConfigHelper.getLowerHexString(length: 13))
            DispatchQueue.main.async {
                self.refreshData()
                self.uiState.deviceFpInfo.makeAlert(msg: error.localizedDescription)
                self.canGoNext = true
            }
        }
    }
}
