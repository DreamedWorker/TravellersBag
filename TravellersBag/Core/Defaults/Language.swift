//
//  Language.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/25.
//

import Foundation

extension UserDefaults {
    /// 自动根据当前的相关信息返回用户语言
    static func getCurrentLangCode() -> String {
        let locale = Locale.autoupdatingCurrent.language.languageCode?.identifier
        return locale ?? "en"
    }
}

extension UserDefaults {
    /// 应用内语言修改
    static func setLanguage(lang: WizardLangs) {
        switch lang {
        case .ZH:
            self.standard.set(["zh-Hans"], forKey: "AppleLanguages")
        case .EN:
            self.standard.set(["en"], forKey: "AppleLanguages")
        }
    }
}
