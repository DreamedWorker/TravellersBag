//
//  DateHelper.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/2/10.
//

import Foundation

class DateHelper {
    /// 字符串（yyyy-MM-dd HH:mm:ss）转时间
    static func string2date(str: String) -> Date {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return format.date(from: str)!
    }
}
