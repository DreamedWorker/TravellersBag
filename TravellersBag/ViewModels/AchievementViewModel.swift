//
//  AchievementViewModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/14.
//

import Foundation
import SwiftData
import SwiftyJSON

extension AchievementView {
    
    class AchievementViewModel: ObservableObject {
        @Published var achieveContent: [AchieveItem] = []
        @Published var achieveList: [AchieveList] = []
        @Published var alertMate = AlertMate()
        
        var archives: [String] = []
        let fs = FileManager.default
        var innerAchieveContent: [JSON]? = nil
        let staticRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(path: "resource").appending(path: "jsons")
        
        func doInit(mc: ModelContext) {
            achieveContent.removeAll(); achieveList.removeAll()
            var achievementFile: [JSON]? = nil
            if UserDefaults.standard.bool(forKey: "useLocalTextResource") {
                if let got = try? JSON(data: Data(contentsOf: staticRoot.appending(component: "AchievementGoal.json"))).arrayValue {
                    achievementFile = got
                } else {
                    achievementFile = try! JSON(data: Data(contentsOf: Bundle.main.url(forResource: "AchievementGoal", withExtension: "json")!)).arrayValue
                }
            } else {
                achievementFile = try! JSON(data: Data(contentsOf: Bundle.main.url(forResource: "AchievementGoal", withExtension: "json")!)).arrayValue
            }
            if UserDefaults.standard.bool(forKey: "useLocalTextResource") {
                if let got = try? JSON(data: Data(contentsOf: staticRoot.appending(component: "Achievement.json"))).arrayValue {
                    innerAchieveContent = got
                } else {
                    innerAchieveContent = try! JSON(data: Data(contentsOf: Bundle.main.url(forResource: "Achievement", withExtension: "json")!)).arrayValue
                }
            } else {
                innerAchieveContent = try! JSON(data: Data(contentsOf: Bundle.main.url(forResource: "Achievement", withExtension: "json")!)).arrayValue
            }
            for i in achievementFile! {
                achieveList.append(
                    AchieveList(id: i["Id"].intValue, order: i["Order"].intValue, name: i["Name"].stringValue, icon: i["Icon"].stringValue)
                )
            }
            let fetcher = FetchDescriptor<AchieveArchive>()
            if let firstOne = try! mc.fetch(fetcher).first {
                let name = firstOne.archName
                let achievements = FetchDescriptor<AchieveItem>(predicate: #Predicate { $0.archiveName == name })
                achieveContent = try! mc.fetch(achievements)
            }
        }
        
        func changeAchieveState(item: AchieveItem, mc: ModelContext) {
            let old = achieveContent.first(where: { $0.id == item.id })!
            old.finished = item.finished
            old.timestamp = item.timestamp
            try! mc.save()
            let name = old.archiveName
            let achievements = FetchDescriptor<AchieveItem>(predicate: #Predicate { $0.archiveName == name })
            achieveContent = try! mc.fetch(achievements)
        }
        
        func createNewArchive(mc: ModelContext, archName: String) {
            if !achieveList.isEmpty && innerAchieveContent != nil {
                let fetcher = FetchDescriptor<AchieveArchive>()
                if !(try! mc.fetch(fetcher).contains(where: { $0.archName == archName })) {
                    let neoArchName = AchieveArchive(archName: archName)
                    mc.insert(neoArchName); try! mc.save()
                    for i in innerAchieveContent! {
                        let single = AchieveItem(
                            archiveName: archName,
                            des: i["Description"].stringValue,
                            goal: i["Goal"].intValue,
                            id: i["Id"].intValue,
                            order: i["Order"].intValue,
                            reward: i["FinishReward"]["Count"].intValue,
                            title: i["Title"].stringValue,
                            version: i["Version"].stringValue,
                            finished: false,
                            timestamp: 0
                        )
                        mc.insert(single)
                    }
                    try! mc.save()
                    alertMate.showAlert(msg: NSLocalizedString("achieve.info.createArchOK", comment: ""))
                    let achievements = FetchDescriptor<AchieveItem>(predicate: #Predicate { $0.archiveName == archName })
                    achieveContent = try! mc.fetch(achievements)
                } else {
                    alertMate.showAlert(msg: NSLocalizedString("achieve.error.same", comment: ""))
                }
            } else {
                alertMate.showAlert(msg: NSLocalizedString("achieve.error.leak_res", comment: ""))
            }
        }
        
        func searchItems(mc: ModelContext, keyWords: String, archive: String) {
            let query = FetchDescriptor<AchieveItem>(predicate: #Predicate{ $0.archiveName == archive && $0.title.contains(keyWords) })
            let result = try? mc.fetch(query)
            if let surely = result {
                achieveContent = surely
            } // 本次搜索无结果 不显示
            else {
                alertMate.showAlert(msg: NSLocalizedString("achieve.info.noSearchResult", comment: ""))
            }
        }
        
        func clearResults(mc: ModelContext, archive: String) {
            let achievements = FetchDescriptor<AchieveItem>(predicate: #Predicate { $0.archiveName == archive })
            achieveContent = try! mc.fetch(achievements)
        }
    }
}
