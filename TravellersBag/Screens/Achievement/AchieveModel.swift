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
    var achieveContent: [AchieveItem] = []
    var achieveList: [AchieveList] = []
    var innerAchieveContent: JSON? = nil
    
    static let shared = AchieveModel()
    private init() {
//        needShowUI()
    }
    
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
                    GlobalUIModel.exported.makeAnAlert(type: 3, msg: "出现未知错误，请删除本存档。")
                }
            } else {
                makeArchFile.clearAll()
                GlobalUIModel.exported.makeAnAlert(type: 3, msg: "存在同名存档。")
                
            }
        } else {
            makeArchFile.clearAll()
            GlobalUIModel.exported.makeAnAlert(type: 3, msg: "有资源缺失，无法创建存档。")
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
                    GlobalUIModel.exported.makeAnAlert(type: 3, msg: "出现未知错误，请删除本存档。")
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
            GlobalUIModel.exported.makeAnAlert(type: 3, msg: "删除失败，\(error.localizedDescription)")
            needShowUI()
        }
    }
}
