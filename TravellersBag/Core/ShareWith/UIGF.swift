//
//  UIGF.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/14.
//

import Foundation
import SwiftyJSON
import SwiftData

final class UIGF: Sendable {
    private init() {}
    static let `shared` = UIGF()
    
    static func exportRecords2UIGFv4(record: [GachaItem], uid: String, fileUri: URL) throws {
        func timeTransfer(d: Date, detail: Bool = true) -> String {
            let df = DateFormatter()
            df.dateFormat = (detail) ? "yyyy-MM-dd HH:mm:ss" : "yyMMdd"
            return df.string(from: d)
        }
        let time = Date().timeIntervalSince1970
        let targetFile = fileUri
        let info = Info(export_timestamp: Int(time)) // 文件头部信息
        var records: [SingleGachaItem] = []
        for i in record {
            let name = i.name
            var name_id = ""
            if ResHandler.default.avatars.contains(where: { $0["Name"].stringValue == name }) {
                if let temp = ResHandler.default.avatars.filter({ $0["Name"].stringValue == name }).first {
                    name_id = String(temp["Id"].intValue)
                } else { continue }
            } else if ResHandler.default.weapon.contains(where: { $0["Name"].stringValue == name }) {
                if let temp = ResHandler.default.weapon.filter({ $0["Name"].stringValue == name }).first {
                    name_id = String(temp["Id"].intValue)
                } else { continue }
            } else { continue }
            records.append(
                SingleGachaItem(
                    uigf_gacha_type: (i.gachaType == "400") ? "301" : i.gachaType,
                    gacha_type: i.gachaType, item_id: String(name_id),
                    time: timeTransfer(d: str2date(ori: i.time)), id: i.id)
            )
        }
        let hk4e = HK4E(uid: uid, list: records)
        let uigf = UIGFFile(info: info, hk4e: [hk4e])
        let encoder = try JSONEncoder().encode(uigf)
        try encoder.write(to: targetFile)
    }
    
    static func updateFromFile(url: URL, uid: String, mc: ModelContext, oriList: [GachaItem]) throws -> Int {
        let jsonData = try JSON(data: Data(contentsOf: url))
        if jsonData["info"]["version"].stringValue != "v4.0" {
            throw NSError(domain: "gacha.update_from_file", code: -3, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("gacha.error.incourrentFileVersion", comment: "")
            ])
        }
        if let thisUserItems = jsonData["hk4e"].arrayValue.first(where: { $0["uid"].stringValue == uid }) {
            let fileContent = thisUserItems["list"].arrayValue
            if fileContent.isEmpty || fileContent.count == 0 {
                return 0
            } else {
                return processHk4e2CoreData(hk4eList: fileContent, uid: uid, mc: mc, gachaList: oriList)
            }
        } else {
            throw NSError(domain: "gacha.update_from_file", code: -3, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("gacha.error.noCurrentAccountData", comment: "")
            ])
        }
    }
    
    static private func processHk4e2CoreData(hk4eList: [JSON], uid: String, mc: ModelContext, gachaList: [GachaItem]) -> Int {
        var count = 0
        for one in hk4eList {
            if one["item_id"].stringValue == "10008" { continue }
            if !gachaList.isEmpty {
                if gachaList.contains(where: { $0.id == one["id"].stringValue }) { continue }
            } // 自动增量更新配置
            if one["uid"].stringValue != uid { continue } //不知道是否会触发
            let neoItem = GachaItem(
                uid: one["uid"].stringValue,
                id: one["id"].stringValue,
                name: one["name"].stringValue,
                time: one["time"].stringValue,
                rankType: one["rank_type"].stringValue,
                itemType: one["item_type"].stringValue,
                gachaType: one["gacha_type"].stringValue
            )
            mc.insert(neoItem)
            count += 1
        }
        try! mc.save()
        return count
    }
    
    static private func str2date(ori: String) -> Date {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df.date(from: ori)!
    }
}
