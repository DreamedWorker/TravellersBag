//
//  TBCoreMain.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/24.
//

import Foundation

struct TBCore {
    private init() {}
    @MainActor static let `shared` = TBCore()
    
    let preference = UserDefaults.init(suiteName: "preferences")!
}
