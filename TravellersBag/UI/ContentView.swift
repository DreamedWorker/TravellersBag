//
//  ContentView.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2024/10/26.
//

import SwiftUI

struct ContentView: View {
    let needShowWizard: Bool
    
    var body: some View {
        if needShowWizard {
            WizardPane()
        } else {
            ContentPane()
        }
    }
}

struct ContentPane: View {
    @StateObject private var model = ContentPaneControl()
    @State var panePart: ContentPart = .Account
    
    var body: some View {
        NavigationSplitView(
            sidebar: {
                List(
                    selection: $panePart,
                    content: {
                        NavigationLink(value: ContentPart.Account, label: { Label("home.sidebar.account", systemImage: "person.crop.circle") })
                        NavigationLink(value: ContentPart.Notice, label: { Label("home.sidebar.notice", systemImage: "bell.badge") })
                    }
                )
            },
            detail: {
                switch panePart {
                case .Account:
                    AccountScreen()
                case .Notice:
                    NoticeScreen()
                }
            }
        )
        .alert(model.alertMate.msg, isPresented: $model.alertMate.showIt, actions: {})
        .onAppear {
            Task {
                await model.refreshDeviceFp(); await model.refreshMetaFile()
            }
        }
    }
}

class ContentPaneControl: ObservableObject {
    @Published var alertMate = AlertMate()
    
    func refreshDeviceFp() async {
        do {
            let currentTime = Int(Date().timeIntervalSince1970)
            let lastTime = UserDefaults.configGetConfig(forKey: "deviceFpLastUpdated", def: 0)
            if currentTime - lastTime >= UserDefaults.configGetConfig(forKey: "settingsFpUpdateCircle", def: 0) {
                let newFp = try await TBDeviceKit.updateDeviceFp()
                UserDefaults.configSetValue(key: "deviceFpLastUpdated", data: currentTime)
                UserDefaults.configSetValue(key: TBData.DEVICE_FP, data: newFp)
            }
        } catch {
            DispatchQueue.main.async {
                let time = Int(Date().timeIntervalSince1970)
                UserDefaults.configSetValue(key: "deviceFpLastUpdated", data: time)
                self.alertMate.showAlert(msg: "我们无法更新你的部分参数，\(error.localizedDescription)")
            }
        }
    }
    
    func refreshMetaFile() async {
        do {
            let currentTime = Int(Date().timeIntervalSince1970)
            let lastTime = UserDefaults.configGetConfig(forKey: "metaLastDownloaded", def: 0)
            if currentTime - lastTime >= UserDefaults.configGetConfig(forKey: "settingsStaticUpdateCircle", def: 0) {
                let staticRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    .appending(component: "resource").appending(component: "jsons").appending(component: "meta.json")
                try await httpSession().download2File(
                    url: staticRoot,
                    req: URLRequest(url: URL(string: "https://metadata.snapgenshin.com/Genshin/CHS/Meta.json")!)
                )
                UserDefaults.configSetValue(key: "metaLastDownloaded", data: currentTime)
            }
        } catch {
            DispatchQueue.main.async {
                let time = Int(Date().timeIntervalSince1970)
                UserDefaults.configSetValue(key: "metaLastDownloaded", data: time)
                self.alertMate.showAlert(msg: "我们无法更新你的部分参数，\(error.localizedDescription)")
            }
        }
    }
}

enum ContentPart {
    case Account; case Notice;
}
