//
//  LocalService.swift
//  NoteWidgetExtension
//
//  Created by 鸳汐 on 2025/1/18.
//

import Foundation

class LocalService {
    private init() {
        allowedList = groupDailyNoteRoot.appending(component: "AllowedList")
        contentList = groupDailyNoteRoot.appending(component: "ContentList")
    }
    static let shared = LocalService()
    
    let groupDailyNoteRoot = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "NV65B8VFUD.TravellersBag")!
        .appending(component: "NoteWidgets")
    let allowedList: URL
    let contentList: URL
    
    func checkIfIsAllowed(uid: String) -> Bool {
        if !FileManager.default.fileExists(atPath: allowedList.toStringPath()) {
            return false
        }
        do {
            let list = try FileManager.default.contentsOfDirectory(atPath: allowedList.toStringPath())
            if list.contains(where: { $0 == "\(uid).json" }) {
                return true
            } else {
                return false
            }
        } catch {
            return false
        }
    }
    
    func write2file(uid: String, date: Date, data: Data) {
        let contentRoot = contentList.appending(component: uid)
        if !FileManager.default.fileExists(atPath: contentRoot.toStringPath()) {
            try! FileManager.default.createDirectory(at: contentRoot, withIntermediateDirectories: true)
        }
        let timeFile = contentRoot.appending(component: "LastUpdateTime.txt")
        let contentFile = contentRoot.appending(component: "WidgetData.json")
        if !FileManager.default.fileExists(atPath: timeFile.toStringPath()) {
            FileManager.default.createFile(atPath: timeFile.toStringPath(), contents: String(0).data(using: .utf8)!)
        }
        if !FileManager.default.fileExists(atPath: contentFile.toStringPath()) {
            FileManager.default.createFile(atPath: contentFile.toStringPath(), contents: nil)
        }
        try! String(date.timeIntervalSince1970).data(using: .utf8)?.write(to: timeFile)
        try! data.write(to: contentFile)
    }
    
    func getCurrentAccount(uid: String) -> AccountInfo {
        let data = try! JSONDecoder().decode(AccountInfo.self, from: Data(contentsOf: allowedList.appending(component: "\(uid).json")))
        return data
    }
}
