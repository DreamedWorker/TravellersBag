//
//  LanguageHelper.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/24.
//

import Foundation

extension TBCore {
    /// 获取系统的默认语言
    func langGetCurrentLanguage() -> String {
        return (UserDefaults.standard.object(forKey: "AppleLanguages") as! NSArray).firstObject as! String
    }
    
    func langWriteNeoLanguage(langType: String) {
        switch langType {
        case "chs":
            UserDefaults.standard.set(["zh-Hans"], forKey: "AppleLanguages")
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
