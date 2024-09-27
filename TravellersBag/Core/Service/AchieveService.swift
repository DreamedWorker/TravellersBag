//
//  AchieveService.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/27.
//

import Foundation

/// 成就服务
class AchieveService {
    private init() {}
    static let `default` = AchieveService()
    let fs = FileManager.default
    
    /// 下载在线资源
    func downloadOnlineResource() async throws {
        let rootPath = try! fs.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(component: "globalStatic")
        if fs.fileExists(atPath: rootPath.toStringPath()) {
            let sunPath = rootPath.appending(component: "cloud")
            if fs.fileExists(atPath: sunPath.toStringPath()) {
                let detail = sunPath.appending(component: "Achievement.json")
                let list = sunPath.appending(component: "AchievementGoal.json")
                let request = URLRequest(url: URL(string: "https://static-next.snapgenshin.com/d/meta/metadata/Genshin/CHS/Achievement.json")!)
                try await httpSession().download2File(url: detail, req: request)
                let request1 = URLRequest(
                    url: URL(string: "https://static-next.snapgenshin.com/d/meta/metadata/Genshin/CHS/AchievementGoal.json")!)
                try await httpSession().download2File(url: list, req: request1)
            } else {
                throw NSError(domain: "icu.bluedream.travellersbag.achieve", code: -3, userInfo: [NSLocalizedDescriptionKey: "文件夹不存在！"])
            }
        } else {
            throw NSError(domain: "icu.bluedream.travellersbag.achieve", code: -3, userInfo: [NSLocalizedDescriptionKey: "文件夹不存在！"])
        }
    }
}
