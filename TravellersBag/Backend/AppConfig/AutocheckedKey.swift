//
//  AutocheckedKey.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/15.
//

import Foundation

class AutocheckedKey {
    let configKey: String
    let isDailyCheckedKey: Bool
    
    init(configKey: String, dailyCheckedKey: Bool = true) {
        self.configKey = configKey
        self.isDailyCheckedKey = dailyCheckedKey
    }
    
    // 如果不是每天检查的 则5天检查一次
    var shouldFetchFromNetwork: Bool {
        guard let lastDate = ConfigManager.localConfigFile.object(forKey: configKey) as? Date else {
            return true
        }
        if isDailyCheckedKey {
            return !Calendar.autoupdatingCurrent.isDateInToday(lastDate)
        } else {
            let current = Date.now
            let difference = Calendar.autoupdatingCurrent.dateComponents([.day], from: lastDate, to: current)
            return difference.day! >= 5
        }
    }
    
    func storeFetch(date: Date) {
        ConfigManager.setSettingsValue(key: configKey, value: date)
    }
}
