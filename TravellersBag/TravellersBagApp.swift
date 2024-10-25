//
//  TravellersBagApp.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/24.
//

import SwiftUI

let groupName = "NV65B8VFUD.travellersbag"

@main
struct TravellersBagApp: App {
    private var needWizard: Bool = false
    init() {
        needWizard = TBCore.shared.configGetConfig(forKey: "currentAppVersion", def: "0.0.0") != "0.0.2"
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(needShowWizard: needWizard)
        }
    }
}
