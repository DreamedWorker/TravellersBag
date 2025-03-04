//
//  ContentView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/3/2.
//

import SwiftUI

struct ContentView: View {
    @State  // 上次使用的软件版本
    private var storedVersion = PreferenceMgr.default.getValue(key: PreferenceMgr.lastUsedAppVersion, def: "0.0.0")
    
    @ViewBuilder
    var body: some View {
        switch storedVersion {
        case "0.0.0":
            WizardScreen()
        default:
            Text("app.name")
        }
    }
}

#Preview {
    ContentView()
}
