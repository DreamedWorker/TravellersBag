//
//  LaunchOptionScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/17.
//

import SwiftUI
import MMKV

struct LaunchOptionScreen: View {
    @StateObject private var model = LauncherModel()
    
    var body: some View {
        ScrollView {
            Form { // 使用兼容层的配置
                Toggle(isOn: $model.isUseLayer, label: { Label("launcher.method.layer", systemImage: "square.3.layers.3d") })
                    .onChange(of: model.isUseLayer){ value in
                        model.isUsrCommand = !value
                        MMKV.default()!.set(value, forKey: model.USE_LAYER)
                    }
                if model.isUseLayer {
                    TextField(
                        "launcher.method.layer_name",
                        text: $model.layerName,
                        onEditingChanged: { isChanged in
                            if isChanged { MMKV.default()!.set(model.layerName, forKey: model.LAYER_NAME) }
                        },
                        onCommit: { MMKV.default()!.set(model.layerName, forKey: model.LAYER_NAME) }
                    ).textFieldStyle(.roundedBorder)
                }
            }.formStyle(.grouped)
            Form { // 使用自定义命令的配置
                VStack {
                    Toggle(isOn: $model.isUsrCommand, label: { Label("launcher.method.command", systemImage: "command") })
                        .onChange(of: model.isUsrCommand){ value in
                            model.isUseLayer = !value
                            MMKV.default()!.set(value, forKey: model.USE_COMMAND)
                        }
                    Text("launcher.method.command_tip").font(.caption)
                }
                if model.isUsrCommand {
                    TextField(
                        "launcher.method.command_detail",
                        text: $model.commands,
                        onEditingChanged: { isChanged in
                            if isChanged { MMKV.default()!.set(model.commands, forKey: model.COMMAND_CONTEXT) }
                        },
                        onCommit: { MMKV.default()!.set(model.commands, forKey: model.COMMAND_CONTEXT) }
                    ).textFieldStyle(.roundedBorder)
                    HStack {
                        Spacer()
                        Button("launcher.method.command_test", action: {
                            model.runTestCommand()
                        })
                    }
                }
            }.formStyle(.grouped)
            HStack {
                Text("launcher.global.tip").font(.footnote)
                Spacer()
            }.padding(.horizontal, 16)
        }.navigationTitle(Text("home.sider.launcher"))
    }
}

#Preview {
    LaunchOptionScreen()
}
