//
//  TravellersBagApp.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/3/2.
//

import SwiftUI
import SwiftData
import Sparkle

@main
struct TravellersBagApp: App {
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [MihoyoAccount.self])
                .frame(minWidth: 1024, minHeight: 600)
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
    }
}
