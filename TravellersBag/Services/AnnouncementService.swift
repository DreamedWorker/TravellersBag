//
//  AnnouncementService.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/12.
//

import Foundation

class AnnouncementService {
    static let shared = AnnouncementService()
    private let localFile = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "announcement.json")
    private init () {
        if !FileManager.default.fileExists(atPath: localFile.path().removingPercentEncoding!) {
            FileManager.default.createFile(atPath: localFile.path().removingPercentEncoding!, contents: nil)
        }
    }
    
    /// 从网络获取活动数据 返回一个活动列表或错误信息字符串
    /// 不推荐调用本方法，建议直接调用 fetchAnnouncement 方法
    func fetchFromNetwork() async throws -> [Announcement] {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getHk4eAnnouncement())!)
        let result = try await req.receiveOrThrow()
        FileHandler.shared.writeUtf8String(path: localFile.path().removingPercentEncoding!, context: result.rawString() ?? "")
        return processData(json: result)
    }
    
    /// 从本地文件读取活动数据 （如果文件内容为空或者无法解析「不存在没有文件的情况」则主动从互联网获取并写入文件）
    func fetchAnnouncement() async throws -> [Announcement] {
        let fileData = FileHandler.shared.readUtf8String(path: localFile.path().removingPercentEncoding!)
        if fileData == "" || fileData.isEmpty {
            return try await fetchFromNetwork()
        } else {
            return processData(json: try JSON(data: fileData.data(using: .utf8)!))
        }
    }
    
    private func processData(json: JSON) -> [Announcement] {
        var anns: [Announcement] = []
        let lists = json["list"].arrayValue
        let p1 = lists[0]["list"].arrayValue.map{ $0.dictionaryObject! }
        let p2 = lists[1]["list"].arrayValue.map{ $0.dictionaryObject! }
        for i1 in p1 {
            anns.append(Announcement(
                annId: i1["ann_id"] as! Int,
                title: i1["title"] as! String,
                subtitle: i1["subtitle"] as! String,
                typeLabel: i1["type_label"] as! String,
                tagLabel: i1["tag_label"] as! String,
                banner: i1["banner"] as? String //这里有个小坑，不是所有的都有大图，引用时仍需进行isEmpty判断。
            ))
        }
        for i1 in p2 {
            anns.append(Announcement(
                annId: i1["ann_id"] as! Int,
                title: i1["title"] as! String,
                subtitle: i1["subtitle"] as! String,
                typeLabel: i1["type_label"] as! String,
                tagLabel: i1["tag_label"] as! String,
                banner: i1["banner"] as? String
            ))
        }
        return anns
    }
}
