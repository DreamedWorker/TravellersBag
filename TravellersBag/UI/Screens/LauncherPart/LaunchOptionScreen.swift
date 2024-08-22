//
//  LaunchOptionScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/17.
//

import SwiftUI

struct LaunchOptionScreen: View {
    @StateObject private var model = LauncherModel()
    
    var body: some View {
        ScrollView {
            VStack {
                HStack(spacing: 16) {
                    Image(systemName: "square.3.layers.3d").font(.title2)
                    Text("launcher.method.layer").font(.title2).bold()
                    Spacer()
                    Toggle(isOn: $model.isUseLayer, label: { Text("launcher.method.use_it") })
                        .onChange(of: model.isUseLayer){ newVar in
                            if newVar {
                                model.isUsrCommand = !newVar
                            } else {
                                model.isUsrCommand = true
                            }
                            model.saveLauncherMethod()
                        }
                }
                .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 8)
                Text("launcher.method.layer.tip").font(.callout)
                    .padding(.horizontal, 16)
                Divider().padding(.horizontal, 16).padding(.vertical, 8)
                HStack(spacing: 16) {
                    Image(systemName: "app").font(.title3)
                    Text("launcher.method.layer_name").font(.title3).bold()
                    Text(model.layerName)
                        .foregroundStyle(.secondary).underline()
                    Spacer()
                    Button("launcher.method.layer_choose", action: {
                        model.chooseWhat = "app"
                        model.showChooseFileWindow = true
                    })
                }.padding(.horizontal, 16).padding(.bottom, 4)
                Text("launcher.method.layer_choose_tip")
                    .font(.footnote).foregroundStyle(.secondary)
                    .padding(.horizontal, 8).padding(.bottom, 16)
            }
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous).fill(AnyShapeStyle(BackgroundStyle()))
            }
            .padding()
            VStack {
                HStack {
                    Image(systemName: "command").font(.title2)
                    Text("launcher.method.command").font(.title2).bold()
                    Spacer()
                    Toggle(isOn: $model.isUsrCommand, label: { Text("launcher.method.use_it") })
                        .onChange(of: model.isUsrCommand){ newVal in
                            if newVal {
                                model.isUseLayer = !newVal
                            } else { 
                                model.isUseLayer = true
                            }
                            model.saveLauncherMethod()
                        }
                }.padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 8)
                Text("launcher.method.command_tip").font(.callout)
                    .padding(.horizontal, 16)
                Divider().padding(.horizontal, 16).padding(.vertical, 8)
                HStack(spacing: 16) {
                    Image(systemName: "doc").font(.title3)
                    Text("launcher.method.command_detail").font(.title3).bold()
                    Spacer()
                    Button("launcher.method.command_choose", action: {
                        model.chooseWhat = "file"
                        model.showChooseFileWindow = true
                    })
                }.padding(.horizontal, 16).padding(.bottom, 4)
                HStack {
                    Text(String.localizedStringWithFormat(NSLocalizedString("launcher.method.command_test", comment: ""), model.commands))
                        .font(.callout)
                    Spacer()
                }.padding(.horizontal, 16).padding(.bottom, 16)
            }
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous).fill(AnyShapeStyle(BackgroundStyle()))
            }
            .padding(.horizontal, 16).padding(.bottom, 16)
        }
        .navigationTitle(Text("home.sider.launcher"))
        .fileImporter(
            isPresented: $model.showChooseFileWindow,
            allowedContentTypes: (model.chooseWhat == "app") ? [.application] : [.shellScript, .text],
            allowsMultipleSelection: false,
            onCompletion: { result in
                do {
                    let app = try result.get()[0]
                    let path = (model.chooseWhat == "app") ?
                    String(app.path().removingPercentEncoding!.split(separator: "/").last!) :
                    String(app.path().removingPercentEncoding!)
                    if model.chooseWhat == "app" {
                        LocalEnvironment.shared.setStringValue(key: "layer_name", value: path)
                        model.layerName = path
                    } else {
                        LocalEnvironment.shared.setStringValue(key: "command_detail", value: path)
                        model.commands = path
                    }
                } catch {
                    model.showChooseFileWindow = false
                    HomeController.shared.showErrorDialog(msg: error.localizedDescription)
                }
            }
        )
    }
}

#Preview {
    LaunchOptionScreen()
}
