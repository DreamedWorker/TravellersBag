//
//  ConfigHelper.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/24.
//

import Foundation

extension TBCore {
    /// 从全局K-V存储中获取值
    func configGetConfig<T>(forKey key: String, def defaultKey: T) -> T {
        if let result = self.preference.object(forKey: key) as? T {
            return result
        } else {
            return defaultKey
        }
    }
    
    /// 将值插入全局K-V中
    func configSetValue<T>(key forKey: String, data value: T) {
        self.preference.set(value, forKey: forKey)
    }
}
