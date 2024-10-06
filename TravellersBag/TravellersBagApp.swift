//
//  TravellersBagApp.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/8.
//

import SwiftUI
import Sentry
import AppKit

@main
struct TravellersBagApp: App {
    @StateObject private var coreDataHelper = CoreDataHelper.shared
    
    init() {
        TBEnv.default.checkEnvironment()
        SentrySDK.start { options in
            options.dsn = "https://94ef38f68876d3a718cf007d6fbb46e1@o4507083124834304.ingest.de.sentry.io/4507887457337424"
            //options.debug = true
            options.tracesSampleRate = 1.0
            options.profilesSampleRate = 1.0
        }
        _ = HoyoResKit.default
    }
    
    var body: some Scene {
        WindowGroup {
            if UserDefaultHelper.shared.getValue(forKey: "currentAppVersion", def: "0.0.0") == "0.0.1" {
                HomeScreen()
                    .environment(\.managedObjectContext, coreDataHelper.persistentContainer.viewContext)
            } else {
                WizardScreen()
            }
        }
        .commands(content: {
            CommandMenu("command.app", content: {
                Button("command.add.check_update", action: {
                    NSWorkspace.shared.open(URL(string: "https://github.com/DreamedWorker/TravellersBag")!)
                }).keyboardShortcut(.init("g"))
            })
        })
    }
}

/// 上传错误
func uploadAnError(fatalInfo: Error){
    SentrySDK.capture(error: fatalInfo)
}

extension URL {
    func toStringPath() -> String {
        return self.path().removingPercentEncoding!
    }
}
