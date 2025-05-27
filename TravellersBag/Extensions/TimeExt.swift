//
//  TimeExt.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/28.
//

import Foundation

extension Int {
    func formatTimestamp() -> String {
        if self == 0 {
            return NSLocalizedString("anno.label.unknown", comment: "")
        }
        let date = Date(timeIntervalSince1970: TimeInterval(self))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        return dateFormatter.string(from: date)
    }
}

extension String {
    func dateFromFormattedString() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        return dateFormatter.date(from: self) ?? Date.now
    }
}
