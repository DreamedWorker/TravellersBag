//
//  TravellersBagApp.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/15.
//

import SwiftUI
import MMKV
import Sentry

@main
struct TravellersBagApp: App {
    @StateObject private var coreDataHelper = CoreDataHelper.shared
    
    init() {
        MMKV.initialize(rootDir: nil) // 默认库 用于存储全局性的kv对
        LocalEnvironment.shared.checkEnvironment()
        SentrySDK.start { options in
            options.dsn = "https://94ef38f68876d3a718cf007d6fbb46e1@o4507083124834304.ingest.de.sentry.io/4507887457337424"
            //options.debug = true
            options.tracesSampleRate = 1.0
            options.profilesSampleRate = 1.0
        }
    }
    
    var body: some Scene {
        WindowGroup {
            HomeContainer()
                .environment(\.managedObjectContext, coreDataHelper.persistentContainer.viewContext)
        }
    }
}
