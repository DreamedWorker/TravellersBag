//
//  UIGFStandard.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/6/1.
//

import Foundation
import SwiftData
import AppKit

class UIGFStandard {
    static func exportGachaRecords(account: String, targetFolder: URL, context: ModelContext) throws {
        let records = try context.fetch(FetchDescriptor(predicate: #Predicate<GachaItem> { $0.uid == account }))
        let currentTime = Date.now
        
        let fileHead = UIGF4.FileMetaData(export_timestamp: Int(currentTime.timeIntervalSince1970))
        var formattedRecords: [UIGF4.Hk4eGame.SingleGachaItem] = []
        for record in records {
            let itemId = StaticHelper.getIdByName(name: record.name)
            if itemId == "0" { continue } // skip if id cannot be found in order to make other uigf-adopted app can recongnize
            formattedRecords.append(UIGF4.Hk4eGame.SingleGachaItem(
                uigf_gacha_type: (record.gachaType == "400") ? "301" : record.gachaType,
                gacha_type: record.gachaType,
                item_id: itemId,
                time: record.time,
                id: record.id
            ))
        }
        
        let result = UIGF4(info: fileHead, hk4e: [UIGF4.Hk4eGame(uid: account, list: formattedRecords)])
        let file = targetFolder.appending(component: "GachaRecords_\(account)_\(currentTime.timeIntervalSince1970).json")
        try FileManager.default.createFile(atPath: file.path(percentEncoded: false), contents: JSONEncoder().encode(result))
    }
    
    @MainActor static func readImputRecords() async -> UIGF4Inner? {
        do {
            let panel = NSOpenPanel()
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            panel.canChooseFiles = true
            panel.message = NSLocalizedString("gacha.panel.importTitle", comment: "")
            await panel.begin()
            if let url = panel.url {
                let structure = try JSONDecoder().decode(UIGF4.self, from: Data(contentsOf: url))
                return UIGF4Inner(
                    context: structure
                )
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}

extension UIGFStandard {
    struct UIGF4Inner: Codable, Identifiable {
        var id: String = UUID().uuidString
        var context: UIGF4
    }
}

extension UIGFStandard {
    struct UIGF4: Codable {
        var info: FileMetaData
        var hk4e: [Hk4eGame]
    }
}

extension UIGFStandard.UIGF4 {
    struct FileMetaData: Codable {
        var export_timestamp: Int // 导出档案的时间戳，秒级
        var export_app: String = "旅者行囊" //导出档案的 App 名称
        var export_app_version: String = "1.0.0(10000)" // 导出档案的 App 版本
        var version: String = "v4.0" // 导出档案的 UIGF 版本号
    }
}

extension UIGFStandard.UIGF4 {
    struct Hk4eGame: Codable {
        var uid: String
        var timezone: Int = 0
        var list: [SingleGachaItem]
    }
}

extension UIGFStandard.UIGF4.Hk4eGame {
    struct SingleGachaItem: Codable {
        var uigf_gacha_type: String // UIGF 卡池类型
        var gacha_type: String // 卡池类型
        var item_id: String // 物品的内部 ID
        var time: String // 抽取物品时对应时区（timezone）下的当地时间
        var id: String // 记录内部 ID
    }
}
