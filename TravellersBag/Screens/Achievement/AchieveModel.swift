//
//  AchieveModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/26.
//

import Foundation
import SwiftyJSON
import CoreData

class AchieveModel: ObservableObject {
    @Published var uiPart: AchievePart = .Loading
    @Published var makeArchFile = MakeArchive()
    
    var dm: NSManagedObjectContext? = nil
    var archives: [String] = []
    let fs = FileManager.default
    @Published var achieveContent: [AchieveItem] = []
    @Published var achieveList: [AchieveList] = []
    var innerAchieveContent: JSON? = nil
    
    static let shared = AchieveModel()
    private init() {}
    
    func initSomething(dm: NSManagedObjectContext) {
        self.dm = dm
        needShowUI()
    }
    
    func createNewArchive() {
        if !achieveList.isEmpty && innerAchieveContent != nil {
            let name = makeArchFile.name
            if !archives.contains(name) {
                archives.append(name)
                UserDefaultHelper.shared.preference!.setRequiredValue(forKey: "achievementArch", value: archives)
                for i in innerAchieveContent!.arrayValue {
                    let single = AchieveItem(context: dm!)
                    single.archiveName = name
                    single.des = i["Description"].stringValue
                    single.goal = Int64(i["Goal"].intValue)
                    single.id = Int64(i["Id"].intValue)
                    single.order = Int64(i["Order"].intValue)
                    single.reward = Int64(i["FinishReward"]["Count"].intValue)
                    single.title = i["Title"].stringValue
                    single.version = i["Version"].stringValue
                }
                _ = CoreDataHelper.shared.save()
                achieveContent.removeAll()
                achieveContent = fetchRequiredItems(name: name)
                if achieveContent.count > 0 {
                    makeArchFile.clearAll()
                    uiPart = .Content
                } else {
                    uiPart = .Loading
                    GlobalUIModel.exported.makeAnAlert(type: 3, msg: NSLocalizedString("achieve.error.unknown", comment: ""))
                }
            } else {
                makeArchFile.clearAll()
                GlobalUIModel.exported.makeAnAlert(type: 3, msg: NSLocalizedString("achieve.error.same", comment: ""))
                
            }
        } else {
            makeArchFile.clearAll()
            GlobalUIModel.exported.makeAnAlert(type: 3, msg: NSLocalizedString("achieve.error.leak_res", comment: ""))
        }
    }
    
    /// 是否需要显示UI
    func needShowUI() {
        achieveContent.removeAll(); achieveList.removeAll()
        let achieveListFile = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(component: "globalStatic").appending(component: "cloud").appending(components: "AchievementGoal.json")
        let achieveDetailFile = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(component: "globalStatic").appending(component: "cloud").appending(components: "Achievement.json")
        archives.removeAll()
        if fs.fileExists(atPath: achieveListFile.toStringPath()) && fs.fileExists(atPath: achieveDetailFile.toStringPath()) {
            let temp = UserDefaultHelper.shared.preference!.getRequiredValue(forKey: "achievementArch", def: [] as [String])
            archives = temp
            if let achieveLists = try? JSON(data: FileHandler.shared.readUtf8String(path: achieveListFile.toStringPath()).data(using: .utf8)!) {
                let context = achieveLists.arrayValue
                for i in context {
                    achieveList.append(AchieveList(id: i["Id"].intValue, order: i["Order"].intValue, name: i["Name"].stringValue, icon: i["Icon"].stringValue))
                }
            }
            innerAchieveContent = try? JSON(data: FileHandler.shared.readUtf8String(path: achieveDetailFile.toStringPath()).data(using: .utf8)!)
            if archives.count > 0 {
                let firstOne = archives.first!
                achieveContent = fetchRequiredItems(name: firstOne)
                if achieveContent.count > 0 {
                    uiPart = .Content
                } else {
                    uiPart = .Loading
                    GlobalUIModel.exported.makeAnAlert(type: 3, msg: NSLocalizedString("achieve.error.unknown", comment: ""))
                }
            } else {
                uiPart = .NoAccount
            }
        } else {
            uiPart = .NoResource
        }
    }
    
    /// 下载在线资源
    func downloadResource() async {
        do {
            try await AchieveService.default.downloadOnlineResource()
            DispatchQueue.main.async { [self] in
                GlobalUIModel.exported.makeAnAlert(type: 1, msg: "更新成功")
                needShowUI()
            }
        } catch {
            DispatchQueue.main.async { [self] in
                GlobalUIModel.exported.makeAnAlert(type: 3, msg: "更新失败：\(error.localizedDescription)")
                needShowUI()
            }
        }
    }
    
    /// 获取指定存档的内容
    func fetchRequiredItems(name: String) -> [AchieveItem] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "AchieveItem")
        request.predicate = NSPredicate(format: "archiveName == %@", name)
        let result = (try? dm!.fetch(request)) as? [AchieveItem]
        if let out = result {
            return out
        } else { return [] }
    }
    
    func changeAchieveState(item: AchieveItem) {
        let old = achieveContent.first(where: { $0.id == item.id})!
        old.finished = item.finished
        old.timestamp = item.timestamp
        _ = CoreDataHelper.shared.save()
        needShowUI()
    }
    
    func deleteAnArchive(name: String) {
        do {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "AchieveItem")
            request.predicate = NSPredicate(format: "archiveName == %@", name)
            let mid = try dm!.fetch(request) as! [AchieveItem]
            for i in mid {
                CoreDataHelper.shared.deleteOne(single: i)
            }
            _ = CoreDataHelper.shared.save()
            archives.remove(at: archives.firstIndex(of: name)!)
            UserDefaultHelper.shared.preference!.setRequiredValue(forKey: "achievementArch", value: archives)
            needShowUI()
        } catch {
            GlobalUIModel.exported.makeAnAlert(
                type: 3,
                msg: String.localizedStringWithFormat(NSLocalizedString("achieve.error.delete", comment: ""), error.localizedDescription)
            )
            needShowUI()
        }
    }
    
    func exportRecords(fileUrl: URL) {
        func timeTransfer(d: Date, detail: Bool = true) -> String {
            let df = DateFormatter()
            df.dateFormat = (detail) ? "yyyy-MM-dd HH:mm:ss" : "yyMMdd"
            return df.string(from: d)
        }
        let time = Date().timeIntervalSince1970
        let targetFile = fileUrl
        do {
            let header = UIAFInfo(export_timestamp: Int(time))
            var list: [UIAFUnit] = []
            for i in achieveContent {
                list.append(UIAFUnit(id: Int(i.id), timestamp: (i.finished) ? Int(i.timestamp) : 0, current: 0, status: (i.finished) ? 2 : 0))
            }
            let final = UIAFFile(info: header, list: list)
            let encoder = try JSONEncoder().encode(final)
            FileHandler.shared.writeUtf8String(path: targetFile.toStringPath(), context: String(data: encoder, encoding: .utf8)!)
            GlobalUIModel.exported.makeAnAlert(type: 1, msg: "导出成功")
        } catch {
            GlobalUIModel.exported.makeAnAlert(type: 3, msg: String.localizedStringWithFormat(
                NSLocalizedString("gacha.export.error", comment: ""), error.localizedDescription))
        }
    }
    
    func updateRecords(fileUrl: URL) {
        let mid = achieveContent
        do {
            let fileContext = try JSON(data: Data(contentsOf: fileUrl))
            if fileContext["info"]["uiaf_version"].stringValue == "v1.1" {
                let lists = fileContext["list"].arrayValue
                for i in lists {
                    if mid.contains(where: { $0.id == Int64(i["id"].intValue) }) {
                        let target = mid.first(where: { $0.id == Int64(i["id"].intValue) })!
                        if i["status"].intValue == 2 {
                            target.finished = true
                            target.timestamp = Int64(i["timestamp"].intValue)
                        } else {
                            target.finished = false
                            target.timestamp = 0
                        }
                    } // 不在我们的列表中的不会添加，避免出现某些意外错误。
                }
                GlobalUIModel.exported.makeAnAlert(type: 1, msg: "操作完成。")
                _ = CoreDataHelper.shared.save()
                needShowUI()
            } else {
                GlobalUIModel.exported.makeAnAlert(type: 3, msg: NSLocalizedString("achieve.error.standard", comment: ""))
            }
        } catch {
            GlobalUIModel.exported.makeAnAlert(type: 3, msg: "导入失败，\(error.localizedDescription)")
        }
    }
}
