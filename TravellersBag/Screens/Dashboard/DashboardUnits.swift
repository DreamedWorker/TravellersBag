//
//  DashboardUnits.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/20.
//

import SwiftUI
import SwiftyJSON
import Kingfisher

struct DashboardUnits {
    /// 启动游戏 -- 功能卡片
    struct LaunchGame: View {
        @State var settingsSheet = false
        @State var inputs = InputGroup()
        let LAUNCH_METHOD = "launchMethod"
        let LAUNCH_DETAIL = "launchDetail"
        
        var body: some View {
            return VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "gamecontroller").font(.title2)
                    Spacer()
                    Image(systemName: "gear").help("dashboard.unit.launcher.settings")
                        .onTapGesture { settingsSheet = true }
                }
                Text("dashboard.unit.launcher.title").font(.title3).bold()
                    .foregroundStyle(Color.accentColor).padding(.top, 8)
                HStack {
                    Button("dashboard.unit.launcher.start", action: {
                        let method = UserDefaultHelper.shared.getValue(forKey: LAUNCH_METHOD, def: "none")
                        if method != "none" {
                            switch method {
                            case "app":
                                runCommand(command: UserDefaultHelper.shared.getValue(forKey: LAUNCH_DETAIL, def: "Finder.app"), type: "app")
                            case "command":
                                runCommand(command: UserDefaultHelper.shared.getValue(forKey: LAUNCH_DETAIL, def: ""), type: "command")
                            default:
                                GlobalUIModel.exported.makeAnAlert(type: 3, msg: "异常")
                            }
                        } else {
                            GlobalUIModel.exported.makeAnAlert(type: 3, msg: NSLocalizedString("dashboard.unit.launcher.error", comment: ""))
                        }
                    }).buttonStyle(BorderedProminentButtonStyle())
                    Spacer()
                    Image("expecting_new_world").resizable().scaledToFit().frame(width: 48, height: 48).opacity(0.7)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
            .sheet(isPresented: $settingsSheet, content: { SettingsSheet })
        }
        
        var SettingsSheet: some View {
            return NavigationStack {
                Text("dashboard.unit.launcher.settings_title").font(.title).bold()
                Form {
                    TextField("dashboard.unit.launcher.settings_app", text: $inputs.appName)
                    TextField("dashboard.unit.launcher.settings_command", text: $inputs.command)
                }.formStyle(.grouped).scrollDisabled(true)
                Text("dashboard.unit.launcher.settings_help")
                    .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.leading)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .destructiveAction, content: {
                    Button("app.cancel", action: {
                        settingsSheet = false
                        inputs.clearAll()
                    })
                })
                ToolbarItem(placement: .confirmationAction, content: {
                    Button("dashboard.unit.launcher.settings_use_app", action: {
                        UserDefaultHelper.shared.setValue(forKey: LAUNCH_METHOD, value: "app")
                        UserDefaultHelper.shared.setValue(forKey: LAUNCH_DETAIL, value: inputs.appName)
                        settingsSheet = false
                        inputs.clearAll()
                    })
                })
                ToolbarItem(placement: .cancellationAction, content: {
                    Button("dashboard.unit.launcher.settings_use_command", action: {
                        UserDefaultHelper.shared.setValue(forKey: LAUNCH_METHOD, value: "command")
                        UserDefaultHelper.shared.setValue(forKey: LAUNCH_DETAIL, value: inputs.command)
                        settingsSheet = false
                        inputs.clearAll()
                    })
                })
            }
        }
        
        struct InputGroup {
            var appName: String
            var command: String
            
            init(appName: String = "", command: String = "") {
                self.appName = appName
                self.command = command
            }
            
            mutating func clearAll() {
                appName = ""; command = ""
            }
        }
        
        private func runCommand(command: String, type: String) {
            let process = Process()
            process.launchPath = "/bin/zsh"
            var commands = ""
            if type == "app" {
                commands = "open -a \(command)"
            } else {
                commands = command
            }
            process.arguments = ["-c", commands]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.launch()
        }
    }
    
    /// 账号基本信息 -- 数据卡片
    struct BasicInfo: View {
        let partData: JSON?
        init(partData: JSON?) {
            self.partData = partData
        }
        
        var body: some View {
            VStack {
                if let data = partData {
                    HStack {
                        Spacer()
                        Text("dashboard.unit.data.title").font(.callout)
                        Spacer()
                    }
                    HStack() {
                        DisplayUnit(title: "dashboard.unit.data.abyss", count: data["spiral_abyss"].stringValue)
                        if data["role_combat"]["has_data"].boolValue {
                            DisplayUnit(title: "dashboard.unit.data.role", count: "第\(data["role_combat"]["max_round_id"].intValue)幕")
                        }
                    }
                    HStack {
                        DisplayUnit(title: "dashboard.unit.data.anemoculus", count: String(data["anemoculus_number"].intValue))
                        DisplayUnit(title: "dashboard.unit.data.geoculus", count: String(data["geoculus_number"].intValue))
                        DisplayUnit(title: "dashboard.unit.data.electroculus", count: String(data["electroculus_number"].intValue))
                        DisplayUnit(title: "dashboard.unit.data.dendroculus", count: String(data["dendroculus_number"].intValue))
                    }
                    HStack {
                        DisplayUnit(title: "dashboard.unit.data.hydroculus", count: String(data["hydroculus_number"].intValue))
                        DisplayUnit(title: "dashboard.unit.data.pyroculus", count: String(data["pyroculus_number"].intValue))
                        DisplayUnit(title: "dashboard.unit.data.avatar", count: String(data["avatar_number"].intValue))
                        DisplayUnit(title: "dashboard.unit.data.achievement", count: String(data["achievement_number"].intValue))
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
        }
        
        private struct DisplayUnit: View {
            let title: String
            let count: String
            
            var body: some View {
                VStack {
                    Text(count).bold()
                    Text(NSLocalizedString(title, comment: "")).font(.footnote)
                }
                .padding(2)
            }
        }
    }
}
