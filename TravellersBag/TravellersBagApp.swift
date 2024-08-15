//
//  TravellersBagApp.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/15.
//

import SwiftUI
import MMKV

@main
struct TravellersBagApp: App {
    @StateObject private var coreDataHelper = CoreDataHelper.shared
    
    init() {
        MMKV.initialize(rootDir: nil) // 默认库 用于存储全局性的kv对
        LocalEnvironment.shared.checkEnvironment()
    }
    
    var body: some Scene {
        WindowGroup {
            HomeContainer()
                .environment(\.managedObjectContext, coreDataHelper.persistentContainer.viewContext)
        }
    }
}
