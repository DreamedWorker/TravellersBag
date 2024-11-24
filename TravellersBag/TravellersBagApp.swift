//
//  TravellersBagApp.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/1.
//

import SwiftUI
import Sparkle

let groupName = "NV65B8VFUD.travellersbag"

@main
struct TravellersBagApp: App {
    private var needWizard: Bool = true
    private let updaterController: SPUStandardUpdaterController
    @State var showHutaoPassport: Bool = false
    
    init() {
        needWizard = UserDefaults.configGetConfig(forKey: "currentAppVersion", def: "0.0.0") != "0.0.2"
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(needShowWizard: needWizard)
        }
    }
}
