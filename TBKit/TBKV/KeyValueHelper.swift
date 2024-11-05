//
//  KeyValueHelper.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2024/10/28.
//

import Foundation

/// 自定义存储
extension UserDefaults {
    public static let preferences = UserDefaults.init(suiteName: "preferences")!
    
    /// 从全局K-V存储中获取值
    static func configGetConfig<T>(forKey key: String, def defaultKey: T) -> T {
        if let result = UserDefaults.preferences.object(forKey: key) as? T {
            return result
        } else {
            return defaultKey
        }
    }
    
    /// 将值插入全局K-V中
    static func configSetValue<T>(key forKey: String, data value: T) {
        UserDefaults.preferences.set(value, forKey: forKey)
    }
}

/// 系统自带存储
extension UserDefaults {
    static func langGetCurrentLanguage() -> String {
        return (UserDefaults.standard.object(forKey: "AppleLanguages") as! NSArray).firstObject as! String
    }
    
    static func langWriteNeoLanguage(langType: String) {
        switch langType {
        case "chs":
            UserDefaults.standard.set(["zh-Hans-CN"], forKey: "AppleLanguages")
            break
        case "en":
            UserDefaults.standard.set([langType], forKey: "AppleLanguages")
            break
        case "def":
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            break
        default:
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            break
        }
        UserDefaults.standard.synchronize()
    }
}

/// 写入应用程序设置
func appPresetSettings() {
    if UserDefaults.configGetConfig(forKey: TBData.settingsUpdateCircle, def: 0) == 0 {
        UserDefaults.configSetValue(key: TBData.settingsUpdateCircle, data: 432000)
    }
    if UserDefaults.configGetConfig(forKey: TBData.settingsFpCircle, def: 0) == 0 {
        UserDefaults.configSetValue(key: TBData.settingsFpCircle, data: 43200)
    }
}
