//
//  NoticeViewModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/8.
//

import Foundation
import SwiftyJSON

extension NoticeView {
    class NoticeViewModel: ObservableObject {
        let storageRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(component: "LocalNotice")
        let noticeList = "NoticeList.json"
        let noticeDetail = "NoticeDetails.json"
        
        @Published var announcementContext: [NoticeEntry] = []
        @Published var announcementDetail: [JSON] = []
        @Published var alertMate = AlertMate()
        
        init() {
            checkFileExists()
        }
        
        private func checkFileExists() {
            if !FileManager.default.fileExists(atPath: storageRoot.toStringPath()) {
                try! FileManager.default.createDirectory(at: storageRoot, withIntermediateDirectories: true)
            }
            if !FileManager.default.fileExists(atPath: storageRoot.appending(component: noticeList).toStringPath()) {
                FileManager.default.createFile(atPath: storageRoot.appending(component: noticeList).toStringPath(), contents: nil)
            }
            if !FileManager.default.fileExists(atPath: storageRoot.appending(component: noticeDetail).toStringPath()) {
                FileManager.default.createFile(atPath: storageRoot.appending(component: noticeDetail).toStringPath(), contents: nil)
            }
        }
        
        /// 读取本地或从云端获取通知列表
        @MainActor func fetchAnnouncements(useNetwork: Bool = false) async {
            let localFile = storageRoot.appending(component: noticeList)
            func getFromNetwork() async {
                var req = URLRequest(url: URL(string: ApiEndpoints.shared.getHk4eAnnouncement())!)
                if let result = try? await JSON(data: req.receiveOrBlackData()) {
                    checkFileExists()
                    if result.contains(where: { $0.0 == "ProgramError" }) {
                        DispatchQueue.main.async {
                            self.alertMate.showAlert(msg: result["ProgramError"].stringValue)
                        }
                    } else {
                        try! result.rawString()!.write(to: localFile, atomically: true, encoding: .utf8)
                        let noticeList = result["list"].arrayValue
                        DispatchQueue.main.async {
                            self.getNoticeProgressed(list: noticeList)
                        }
                    }
                } else {
                    // 返回值为空
                    DispatchQueue.main.async {
                        self.alertMate.showAlert(msg: NSLocalizedString("notice.error.empty", comment: ""))
                    }
                }
            }
            func getFromDisk() async {
                if FileManager.default.fileExists(atPath: localFile.toStringPath()) {
                    do {
                        let contents = try JSON(data: Data(contentsOf: localFile))
                        DispatchQueue.main.async {
                            self.getNoticeProgressed(list: contents["list"].arrayValue)
                        }
                    } catch {
                        await getFromNetwork()
                    }
                }
            }
            
            if useNetwork {
                await getFromNetwork()
            } else {
                await getFromDisk()
            }
        }
        
        @MainActor func fetchAnnouncementDetails(useNetwork: Bool = false) async {
            let localFile = storageRoot.appending(component: noticeDetail)
            func getFromNetwork() async {
                var req = URLRequest(url: URL(string: ApiEndpoints.shared.getHk4eAnnounceContext())!)
                if let result = try? await JSON(data: req.receiveOrBlackData()) {
                    checkFileExists()
                    if result.contains(where: { $0.0 == "ProgramError" }) {
                        // 在这里抛出错误弹窗，结束后续执行
                        DispatchQueue.main.async {
                            self.alertMate.showAlert(msg: result["ProgramError"].stringValue)
                        }
                    } else {
                        try! result.rawString()!.write(to: localFile, atomically: true, encoding: .utf8)
                        DispatchQueue.main.async {
                            for i in result["list"].arrayValue { self.announcementDetail.append(i) }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.alertMate.showAlert(msg: NSLocalizedString("notice.error.empty", comment: ""))
                    }
                }
            }
            func getFromDisk() async {
                if FileManager.default.fileExists(atPath: localFile.toStringPath()) {
                    do {
                        let context = try JSON(data: Data(contentsOf: localFile))
                        DispatchQueue.main.async {
                            for i in context["list"].arrayValue { self.announcementDetail.append(i) }
                        }
                    } catch {
                        await getFromNetwork()
                    }
                }
            }
            
            if useNetwork {
                await getFromNetwork()
            } else {
                await getFromDisk()
            }
        }
        
        @MainActor func forceRefresh() async {
            DispatchQueue.main.async { [self] in
                announcementDetail = []; announcementContext = []
            }
            let localDetail = storageRoot.appending(component: noticeDetail)
            if FileManager.default.fileExists(atPath: localDetail.toStringPath()) { try! FileManager.default.removeItem(at: localDetail) }
            let localList = storageRoot.appending(component: noticeList)
            if FileManager.default.fileExists(atPath: localList.toStringPath()) { try! FileManager.default.removeItem(at: localList) }
            await fetchAnnouncements(useNetwork: true)
            await fetchAnnouncementDetails(useNetwork: true)
        }
        
        /// 处理已经被初步处理过了的通知 这个一般是用于从云获取之后的通知筛选
        private func getNoticeProgressed(list: [JSON]) {
            var temp: [NoticeEntry] = []
            for i in list {
                let i1 = i["list"].arrayValue
                for j in i1 {
                    temp.append(
                        NoticeEntry(
                            id: j["ann_id"].intValue,annId: j["ann_id"].intValue, title: j["title"].stringValue,
                            subtitle: j["subtitle"].stringValue, banner: j["banner"].stringValue, type_label: j["type_label"].stringValue,
                            type: j["type"].intValue, start: j["start_time"].stringValue, end: j["end_time"].stringValue,
                            tag_label: j["tag_label"].stringValue
                        )
                    )
                }
            }
            temp = temp.sorted(by: { string2date(str: $0.start) > string2date(str: $1.start) })
            announcementContext = temp
        }
        
        func getNoticeDetailEntry(id: Int) -> JSON? {
            return announcementDetail.filter({ $0["ann_id"].intValue == id }).first
        }
        
        /// 字符串转时间对象
        private func string2date(str: String) -> Date {
            let format = DateFormatter()
            format.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return format.date(from: str)!
        }
    }
}
