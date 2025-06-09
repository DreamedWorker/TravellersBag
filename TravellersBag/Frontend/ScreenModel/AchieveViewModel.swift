//
//  AchieveViewModel.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/6/9.
//

import Foundation
import SwiftData
import AppKit

class AchieveViewModel: ObservableObject {
    @Published var uiState: AchievementUiState = .init()
    let achieveListFile = StaticResource.getRequiredFile(name: "AchievementGoal.json")
    let achievementsFile = StaticResource.getRequiredFile(name: "Achievement.json")
    
    func createArch(name: String, operation: ModelContext) throws {
        if name == "" {
            throw NSError(domain: "AchievementArchive", code: -3, userInfo: [NSLocalizedDescriptionKey: "Ilegal arch name!"])
        }
        let count = try operation.fetch(FetchDescriptor(predicate: #Predicate<AchieveArchive> { $0.archName == name })).count
        if count > 0 {
            throw NSError(domain: "AchievementArchive", code: -1, userInfo: [NSLocalizedDescriptionKey: "Arch already exists."])
        }
        let storedItems = try JSONDecoder().decode(AchievementItem.self, from: Data(contentsOf: achievementsFile))
        let neoArch = AchieveArchive(archName: name)
        operation.insert(neoArch)
        try operation.save()
        for item in storedItems {
            let neoItem = AchieveItem(
                archiveName: name, des: item.description, goal: item.goal, id: item.id, order: item.order,
                reward: item.finishReward.count, title: item.title, version: item.version, finished: false, timestamp: 0
            )
            operation.insert(neoItem)
        }
        try operation.save()
        let record = try operation.fetch(FetchDescriptor(predicate: #Predicate<AchieveItem> { $0.archiveName == name }))
        uiState.records = record
        uiState.archName = name
        uiState.showLogic = .fine
    }
    
    func initView(operation: ModelContext) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: achievementsFile.path(percentEncoded: false)) && fileManager.fileExists(atPath: achieveListFile.path(percentEncoded: false)) {
            let archives = try! operation.fetch(FetchDescriptor<AchieveArchive>())
            if !archives.isEmpty {
                do {
                    uiState.achievementGroup = try JSONDecoder().decode(AchievementGroup.self, from: Data(contentsOf: achieveListFile))
                    let archName = archives.first!.archName
                    let record = try operation.fetch(FetchDescriptor(predicate: #Predicate<AchieveItem> { $0.archiveName == archName }))
                    uiState.records = record
                    uiState.archName = archName
                    uiState.showLogic = .fine
                } catch {
                    uiState.mate.showAlert(
                        msg: String.localizedStringWithFormat(
                            NSLocalizedString("achieve.error.loadArch", comment: ""), error.localizedDescription
                        ),
                        type: .Error
                    )
                }
            } else {
                uiState.showLogic = .lackArchs
            }
        } else {
            uiState.showLogic = .lackFiles
        }
    }
    
    func countItems(for id: Int) -> (total: Int, completed: Int) {
        var total = 0
        var completed = 0
        for item in uiState.records {
            if item.goal == id {
                total += 1
                if item.finished {
                    completed += 1
                }
            }
        }
        return (total, completed)
    }
    
    func doSearch(words: String) {
        var tempList = uiState.records
        tempList = tempList.filter({ $0.des.contains(words) || $0.title.contains(words) })
        uiState.records = tempList
    }
    
    func remake(operation: ModelContext) {
        let name = uiState.archName
        let record = try! operation.fetch(FetchDescriptor(predicate: #Predicate<AchieveItem> { $0.archiveName == name }))
        uiState.records = record
    }
    
    @MainActor func exportRecords() async {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = NSLocalizedString("gacha.panel.saveTitle", comment: "")
        await panel.begin()
        if let path = panel.url {
            do {
               try UIAFStandard.exportAchievementRecords(records: uiState.records, selectedPath: path, name: uiState.archName)
                DispatchQueue.main.async {
                    self.uiState.mate.showAlert(msg: NSLocalizedString("app.done", comment: ""))
                }
            } catch {
                DispatchQueue.main.async {
                    self.uiState.mate.showAlert(
                        msg: String.localizedStringWithFormat(
                            NSLocalizedString("achieve.error.export", comment: ""), error.localizedDescription
                        ),
                        type: .Error
                    )
                }
            }
        }
    }
}

extension AchieveViewModel {
    struct AchievementUiState {
        var showLogic: UiPart = .waiting
        var records: [AchieveItem] = []
        var achievementGroup: AchievementGroup = .init()
        var mate: AlertMate = .init()
        var archName: String = ""
        
        enum UiPart {
            case waiting
            case lackFiles
            case lackArchs
            case fine
        }
    }
}
