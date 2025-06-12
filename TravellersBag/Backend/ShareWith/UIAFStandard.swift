//
//  UIAFStandard.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/6/9.
//

import Foundation
import AppKit

class UIAFStandard {
    static func exportAchievementRecords(records: [AchieveItem], selectedPath: URL, name: String) throws {
        let currentTime = Date.now
        let fileHead = UIAF.UIAFInfo(export_timestamp: Int(currentTime.timeIntervalSince1970))
        var formattedRecords: [UIAF.UIAFUnit] = []
        for single in records {
            formattedRecords.append(
                .init(id: single.id, timestamp: (single.finished) ? single.timestamp : 0, current: 30, status: (single.finished) ? 2 : 0)
            )
        }
        let result = UIAF(info: fileHead, list: formattedRecords)
        let file = selectedPath.appending(component: "AchievementRecords_\(name)_\(currentTime.timeIntervalSince1970).json")
        try FileManager.default.createFile(atPath: file.path(percentEncoded: false), contents: JSONEncoder().encode(result))
    }
    
    @MainActor static func readUIAFFile() async -> UIAF11Inner? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.message = NSLocalizedString("achieve.panel.importTitle", comment: "")
        await panel.begin()
        do {
            if let url = panel.url {
                let structure = try JSONDecoder().decode(UIAF.self, from: Data(contentsOf: url))
                return UIAF11Inner(context: structure)
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}

extension UIAFStandard {
    struct UIAF11Inner: Codable, Identifiable {
        var id: String = UUID().uuidString
        var context: UIAF
    }
    
    struct UIAF: Codable {
        var info: UIAFInfo
        var list: [UIAFUnit]
    }
}

extension UIAFStandard.UIAF {
    struct UIAFInfo: Codable {
        var export_timestamp: Int // 导出档案的时间戳，秒级
        var export_app: String = "旅者行囊" //导出档案的 App 名称
        var export_app_version: String = "1.0.0(10000)" // 导出档案的 App 版本
        var uiaf_version: String = "v1.1" // 导出档案的 UIAF 版本号
    }
    
    struct UIAFUnit: Codable {
        var id: Int
        var timestamp: Int
        var current: Int
        var status: Int
    }
}
