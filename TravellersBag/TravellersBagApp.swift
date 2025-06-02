//
//  TravellersBagApp.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/13.
//

import SwiftUI
import SwiftData

@main
struct TravellersBagApp: App {
    @NSApplicationDelegateAdaptor(TravellersBagDelegate.self) private var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [HoyoAccount.self, GachaItem.self, HutaoPassport.self])
        }
        .commands(content: {
            CommandGroup(replacing: .newItem) {}
        })
        Settings {
            SettingsPane()
        }
        .defaultSize(width: 600, height: 400)
        .windowResizability(.contentSize)
    }
}

class TravellersBagDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true // 在最后一个窗口关闭时退出应用 不再保留打开状态
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        Task.detached {
            DeviceEnv.checkEnvironment() // 检查 deviceID 和 bbsDeviceID 是否存在
            StaticResource.checkExistWhenLaunching() // 检查 json 文件目录是否存在
            PicResource.checkWhenLaunching()
            switch await DeviceEnv.deviceFp.getDeviceFp() {
            case .success(let fp):
                print("设备指纹是：\(fp)")
            case .failure(let failed):
                print("无法获取设备指纹：\(failed.localizedDescription)")
            }
        }
    }
}
