//
//  ConfigManager.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/15.
//

import Foundation

class ConfigManager {
    nonisolated(unsafe) static let localConfigFile = UserDefaults.init(suiteName: "travellersbag-next")!
    
    static func getSettingsValue<T>(key: String, value: T) -> T {
        if let result = localConfigFile.object(forKey: key) {
            return result as! T
        } else {
            return value
        }
    }
    
    static func setSettingsValue<T>(key: String, value: T) {
        localConfigFile.set(value, forKey: key)
    }
}
