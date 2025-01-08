//
//  TBCoreMain.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/24.
//

import Foundation

struct TBCore {
    private init() {}
    static let `shared` = TBCore()
}

struct TBData {
    private init() {}
    static let shared = TBData()
}

struct TBKit {
    private init() {}
    static let shared = TBKit()
}
