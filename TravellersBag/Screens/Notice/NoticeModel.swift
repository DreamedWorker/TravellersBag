//
//  NoticeModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/19.
//

import Foundation
import SwiftyJSON

class NoticeModel: ObservableObject {
    let noticeRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "notice")
    let fs = FileManager.default
    init() {
        if !FileManager.default.fileExists(atPath: noticeRoot.toStringPath()) {
            try! FileManager.default.createDirectory(at: noticeRoot, withIntermediateDirectories: true)
        }
    }
    
    @Published var announcementContext: [NoticeEntry] = []
    @Published var announcementDetail: [JSON] = []
    
    /// 获取通知并显示
    func fetchNews() async {
        let localFile = noticeRoot.appending(component: "notice_list.json")
        if fs.fileExists(atPath: localFile.toStringPath()) {
            do {
                let context = try JSON(data: FileHandler.shared.readUtf8String(path: localFile.toStringPath()).data(using: .utf8)!)
                DispatchQueue.main.async {
                    self.getNoticeProgressed(list: context["list"].arrayValue)
                }
            } catch {
                DispatchQueue.main.async {
                    GlobalUIModel.exported.makeAnAlert(type: 3, msg: NSLocalizedString("notice.error.fetch_notice_list_local", comment: ""))
                }
            }
        } else {
            fs.createFile(atPath: localFile.toStringPath(), contents: nil)
            do {
                var req = URLRequest(url: URL(string: ApiEndpoints.shared.getHk4eAnnouncement())!)
                let result = try await req.receiveOrThrow()
                FileHandler.shared.writeUtf8String(path: localFile.toStringPath(), context: result.rawString()!)
                let noticeList = result["list"].arrayValue
                DispatchQueue.main.async {
                    self.getNoticeProgressed(list: noticeList)
                }
            } catch {
                uploadAnError(fatalInfo: error)
                DispatchQueue.main.async {
                    GlobalUIModel.exported.makeAnAlert(
                        type: 3,
                        msg: String.localizedStringWithFormat(
                            NSLocalizedString("notice.error.fetch_notice_list", comment: ""), error.localizedDescription)
                    )
                }
            }
        }
    }
    
    /// 获取通知的详细信息
    func fetchNewsDetail() async {
        let localFile = noticeRoot.appending(component: "notice_context.json")
        if fs.fileExists(atPath: localFile.toStringPath()) {
            do {
                let context = try JSON(data: FileHandler.shared.readUtf8String(path: localFile.toStringPath()).data(using: .utf8)!)
                DispatchQueue.main.async {
                    for i in context["list"].arrayValue { self.announcementDetail.append(i) }
                }
            } catch {
                DispatchQueue.main.async {
                    GlobalUIModel.exported.makeAnAlert(type: 3, msg: NSLocalizedString("notice.error.fetch_notice_list_local", comment: ""))
                }
            }
        } else {
            fs.createFile(atPath: localFile.toStringPath(), contents: nil)
            do {
                var req = URLRequest(url: URL(string: ApiEndpoints.shared.getHk4eAnnounceContext())!)
                let result = try await req.receiveOrThrow()
                FileHandler.shared.writeUtf8String(path: localFile.toStringPath(), context: result.rawString()!)
                DispatchQueue.main.async {
                    for i in result["list"].arrayValue { self.announcementDetail.append(i) }
                }
            } catch {
                uploadAnError(fatalInfo: error)
                DispatchQueue.main.async {
                    GlobalUIModel.exported.makeAnAlert(
                        type: 3,
                        msg: String.localizedStringWithFormat(
                            NSLocalizedString("notice.error.fetch_notice_detail", comment: ""), error.localizedDescription)
                    )
                }
            }
        }
    }
    
    func refreshSource() async {
        DispatchQueue.main.async { [self] in
            announcementDetail = []; announcementContext = []
        }
        let localDetail = noticeRoot.appending(component: "notice_context.json")
        if fs.fileExists(atPath: localDetail.toStringPath()) { try! fs.removeItem(at: localDetail) }
        let localList = noticeRoot.appending(component: "notice_list.json")
        if fs.fileExists(atPath: localList.toStringPath()) { try! fs.removeItem(at: localList) }
        await fetchNews()
        await fetchNewsDetail()
    }
    
    func getNoticeDetailEntry(id: Int) -> JSON? {
        return announcementDetail.filter({ $0["ann_id"].intValue == id }).first
    }
    
    /// 处理已经被初步处理过了的通知 这个一般是用于从云获取之后的通知筛选
    private func getNoticeProgressed(list: [JSON]) {
        var temp: [NoticeEntry] = []
        for i in list {
            let i1 = i["list"].arrayValue
            for j in i1 {
                temp.append(
                    NoticeEntry(
                        annId: j["ann_id"].intValue, title: j["title"].stringValue, subtitle: j["subtitle"].stringValue,
                        banner: j["banner"].stringValue, type_label: j["type_label"].stringValue, type: j["type"].intValue,
                        start: j["start_time"].stringValue, end: j["end_time"].stringValue)
                )
            }
        }
        temp = temp.sorted(by: { string2date(str: $0.start) > string2date(str: $1.start) })
        announcementContext = temp
    }
    
    /// 字符串转时间对象
    private func string2date(str: String) -> Date {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return format.date(from: str)!
    }
}

struct NoticeEntry {
    var annId: Int
    var title: String
    var subtitle: String
    var banner: String
    var type_label: String
    var type: Int
    var start: String
    var end: String
}
