//
//  TravellersBagApp.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/5.
//

import SwiftUI
import MMKV

@main
struct TravellersBagApp: App {
    
    init() {
        MMKV.initialize(rootDir: nil) //默认库 用于存储全局性的kv对
    }
    
    var body: some Scene {
        WindowGroup {
            if MMKV.defaultMMKV(withCryptKey: nil)!.string(forKey: "appVersion", defaultValue: "0.0.0")! == "0.0.1" {
                ContentView()
            } else {
                WizardScene()
                    .frame(width: 600, height: 600)
            }
        }
    }
}
