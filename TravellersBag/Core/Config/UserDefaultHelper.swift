//
//  UserDefaultHelper.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/8.
//

import Foundation

/// Apple的UserDefaults封装类
class UserDefaultHelper {
    let preference = UserDefaults.init(suiteName: "preferences")
    private init() {}
    static let shared = UserDefaultHelper()
    
    /// 读取一个值，为空的返回def的值
    func getValue(forKey: String, def: String) -> String {
        if let result = preference?.object(forKey: forKey) as? String {
            return result
        } else {
            return def
        }
    }
    
    /// 保存一个值
    func setValue(forKey: String, value: String) {
        preference?.set(value, forKey: forKey)
    }
}
