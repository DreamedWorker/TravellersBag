//
//  UIAF.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/15.
//

import Foundation
import SwiftyJSON
import SwiftData

final class UIAF: Sendable {
    private init() {}
    static let `shared` = UIAF()
    
    func exportRecords(fileUrl: URL, achieveContent: [AchieveItem]) throws {
        func timeTransfer(d: Date, detail: Bool = true) -> String {
            let df = DateFormatter()
            df.dateFormat = (detail) ? "yyyy-MM-dd HH:mm:ss" : "yyMMdd"
            return df.string(from: d)
        }
        let time = Date().timeIntervalSince1970
        let header = UIAFInfo(export_timestamp: Int(time))
        var list: [UIAFUnit] = []
        for i in achieveContent {
            list.append(UIAFUnit(id: Int(i.id), timestamp: (i.finished) ? Int(i.timestamp) : 0, current: 0, status: (i.finished) ? 2 : 0))
        }
        let final = UIAFFile(info: header, list: list)
        let encoder = try JSONEncoder().encode(final)
        try encoder.write(to: fileUrl)
    }
    
    func updateRecords(fileUrl: URL, mc: ModelContext, archName: String) throws {
        let fetcher = FetchDescriptor<AchieveItem>(predicate: #Predicate{ $0.archiveName == archName })
        let records = try! mc.fetch(fetcher)
        let fileContext = try JSON(data: Data(contentsOf: fileUrl))
        if fileContext["info"]["uiaf_version"].stringValue == "v1.1" {
            let lists = fileContext["list"].arrayValue
            for i in lists {
                if records.contains(where: { $0.id == i["id"].intValue }) {
                    let target = records.first(where: { $0.id == i["id"].intValue })!
                    if i["status"].intValue == 2 {
                        target.finished = true
                        target.timestamp = i["timestamp"].intValue
                    } else {
                        target.finished = false
                        target.timestamp = 0
                    }
                } // 不在我们的列表中的不会添加，避免出现某些意外错误。
            }
            try! mc.save()
        } else {
            throw NSError(domain: "gacha.update_from_file", code: -3, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("gacha.error.incourrentFileVersion", comment: "")
            ])
        }
    }
}
