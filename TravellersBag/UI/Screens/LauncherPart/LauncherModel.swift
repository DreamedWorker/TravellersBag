//
//  LauncherModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/17.
//

import Foundation
import MMKV

class LauncherModel: ObservableObject {
    let USE_LAYER = "use_layer"
    let LAYER_NAME = "layer_name"
    let USE_COMMAND = "use_command"
    let COMMAND_CONTEXT = "command_detail"
    
    @Published var isUseLayer = MMKV.default()!.bool(forKey: "use_layer", defaultValue: true)
    @Published var isUsrCommand = MMKV.default()!.bool(forKey: "use_command", defaultValue: false)
    @Published var layerName = MMKV.default()!.string(forKey: "layer_name", defaultValue: "CrossOver.app")!
    @Published var commands = MMKV.default()!.string(forKey: "command_detail", defaultValue: "")!
    @Published var showChooseFolderWindow = false
    @Published var showChooseFileWindow = false
    @Published var chooseWhat = "app"
    
    func saveLauncherMethod() {
        MMKV.default()!.set(isUseLayer, forKey: USE_LAYER)
        MMKV.default()!.set(isUsrCommand, forKey: USE_COMMAND)
    }
    
    func runTestCommand() {
        let process = Process()
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", commands]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        do {
            if let data = try pipe.fileHandleForReading.readToEnd() {
                HomeController.shared.showInfomationDialog(msg: String(data: data, encoding: .utf8) ?? "Success but no data read.")
            } else {
                HomeController.shared.showErrorDialog(msg: NSLocalizedString("launcher.global.error_test_command", comment: ""))
            }
        } catch {
            HomeController.shared.showInfomationDialog(msg: error.localizedDescription)
        }
    }
}
