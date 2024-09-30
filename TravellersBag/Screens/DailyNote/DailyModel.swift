//
//  DailyModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/30.
//

import Foundation
import SwiftyJSON

class DailyModel: ObservableObject {
    static let shared = DailyModel()
    let fs = FileManager.default
    let dailyFile = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "daily_note.json")
    
    @Published var showUI: Bool = false
    @Published var dailyContext: JSON? = nil
    @Published var archonTasks: [ArchonTask] = []
    @Published var expeditionTasks: [ExpeditionTask] = []
    
    private init() {
        if !fs.fileExists(atPath: dailyFile.toStringPath()) {
            fs.createFile(atPath: dailyFile.toStringPath(), contents: nil)
        }
        readContext()
    }
    
    /// 读取数据（或用作更新本地数据后的刷新）
    func readContext() {
        dailyContext = nil
        do {
            let context = FileHandler.shared.readUtf8String(path: dailyFile.toStringPath())
            if context == "" || context.isEmpty {
                showUI = false
            } else {
                dailyContext = try JSON(data: context.data(using: .utf8)!)
                if dailyContext != nil {
                    processData()
                    showUI = true
                }
            }
        } catch {
            showUI = false
            GlobalUIModel.exported.makeAnAlert(type: 3, msg: NSLocalizedString("daily.error.read_local", comment: ""))
        }
    }
    
    private func processData() {
        archonTasks.removeAll()
        for i in dailyContext!["archon_quest_progress"]["list"].arrayValue {
            archonTasks.append(
                ArchonTask(
                    id: i["id"].intValue, chapter_title: i["chapter_title"].stringValue, chapter_num: i["chapter_num"].stringValue,
                    status: i["status"].stringValue, chapter_type: i["chapter_type"].intValue)
            )
        }
        expeditionTasks.removeAll()
        for i in dailyContext!["expeditions"].arrayValue {
            expeditionTasks.append(
                ExpeditionTask(
                    avatar_side_icon: i["avatar_side_icon"].stringValue.replacingOccurrences(of: "\\", with: ""), status: i["status"].stringValue,
                    remained_time: i["remained_time"].stringValue, id: UUID().uuidString)
            )
        }
    }
    
    /// 获取数据（完成后自动调用加载函数刷新）
    func updateNoteInfo() async {
        let uid =  ApiEndpoints.shared.getWidgetFull(uid: GlobalUIModel.exported.defAccount!.genshinUID!)
        do {
            var req = URLRequest(url: URL(string: uid)!)
            req.setXRPCAppInfo(client: "5")
            req.setHost(host: "api-takumi-record.mihoyo.com")
            req.setIosUA()
            req.setReferer(referer: "https://webstatic.mihoyo.com/")
            req.setValue("https://webstatic.mihoyo.com", forHTTPHeaderField: "Origin")
            req.setDeviceInfoHeaders()
            req.setDS(version: .V2, type: .X4, q: "role_id=\(uid)&server=cn_gf01", include: false)
            let result = try await req.receiveOrThrow()
            FileHandler.shared.writeUtf8String(path: dailyFile.toStringPath(), context: result.rawString()!)
            DispatchQueue.main.async { [self] in
                GlobalUIModel.exported.makeAnAlert(type: 1, msg: "操作完成")
                readContext()
            }
        } catch {
            DispatchQueue.main.async {
                GlobalUIModel.exported.makeAnAlert(type: 3, msg: "获取信息时失败，\(error.localizedDescription)")
            }
        }
    }
    
    /// 将秒转换为【xx分xx秒】的形式
    func seconds2text(second: String) -> String {
        let target = Int(second)!
        let hours = target / 3600
        let minutes = (target % 3600) / 60
        //let seconds = target % 60
        if hours > 0 {
            return String(format: "%02d小时%02d分钟", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%02d分钟", minutes)
        } else {
            return "即将完成"
        }
    }
}
