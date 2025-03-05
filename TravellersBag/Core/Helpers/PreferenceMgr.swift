//
//  PreferenceMgr.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/3/3.
//

import Foundation

final class PreferenceMgr {
    private var configDB: UserDefaults
    private init() {
        configDB = UserDefaults.init(suiteName: "travellersbag-next")!
    }
    
    static var `default`: PreferenceMgr = PreferenceMgr()
    
    func getValue<T>(key: String, def: T) -> T {
        let value = configDB.object(forKey: key) as? T
        if value == nil {
            return def
        } else {
            return value!
        }
    }
    
    func setValue<T>(key: String, val: T) {
        configDB.set(val, forKey: key)
    }
}

extension PreferenceMgr {
    static var lastUsedAppVersion = "lastUsedAppVersion"
}
