//
//  SettingsPane.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/31.
//

import SwiftUI

struct SettingsPane: View {
    @StateObject private var model = SettingsPaneModel()
    @State private var part: SettingPart = .General
    
    var body: some View {
        NavigationStack {
            TabView(selection: $part, content: {
                GeneralUsed.tabItem({ Label("settings.title.general", systemImage: "gear") }).tag(SettingPart.General)
            })
        }
        .padding()
        .navigationTitle(Text("app.settings"))
    }
    
    var GeneralUsed: some View {
        return Form {
            VStack {
                HStack {
                    TextField(
                        text: $model.updateCircle,
                        label: { Label("settings.general.staticUpdateCircle", systemImage: "timer")}
                    )
                    .onChange(of: model.updateCircle){
                        model.circleUpdated()
                    }
                    Text("settings.unit.day")
                }
                Text("settings.general.staticUpdateCircleP").font(.footnote).foregroundStyle(.secondary)
            }
            HStack {
                TextField(text: $model.deviceFpCircle, label: { Label("settings.general.fpUpdateCircle", systemImage: "hand.point.up.left")})
                    .onChange(of: model.deviceFpCircle, { model.fpUpdated() })
                    .onChange(of: model.deviceFpCircle, { model.fpUpdated() })
                Text("settings.unit.day")
            }
        }.formStyle(.grouped)
    }
    
    enum SettingPart {
        case General
    }
}

private class SettingsPaneModel: ObservableObject {
    @Published var updateCircle = String(Int((UserDefaults.configGetConfig(forKey: TBData.settingsUpdateCircle, def: 0)) / 86400))
    @Published var deviceFpCircle = String(Int((UserDefaults.configGetConfig(forKey: TBData.settingsFpCircle, def: 0)) / 86400))
    
    func circleUpdated() {
        if !updateCircle.isEmpty {
            let temp = Int(updateCircle) ?? 0
            if temp > 0 && temp <= 10 {
                UserDefaults.configSetValue(
                    key: "settingsStaticUpdateCircle",
                    data: Int(Int(updateCircle)! * 86400)
                )
            }
        }
        updateCircle = String(Int((UserDefaults.configGetConfig(forKey: TBData.settingsUpdateCircle, def: 0)) / 86400))
    }
    
    func fpUpdated() {
        if !deviceFpCircle.isEmpty {
            let temp = Int(deviceFpCircle) ?? 0
            if temp > 3 && temp <= 7 {
                UserDefaults.configSetValue(key: TBData.settingsFpCircle, data: Int(Int(deviceFpCircle)! * 86400))
            }
        }
        deviceFpCircle = String(Int((UserDefaults.configGetConfig(forKey: TBData.settingsFpCircle, def: 0)) / 86400))
    }
}
