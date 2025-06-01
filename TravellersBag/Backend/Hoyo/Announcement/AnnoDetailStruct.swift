//
//  AnnoDetailStruct.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/28.
//

import Foundation

class AnnoDetailRepo: AutocheckedKey {
    private let repoKey = "AnnouncementDetailLastFetch"
    private let annoRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(path: "Anno")
    private let annoFile = "AnnoDetail.json"
    
    init() {
        super.init(configKey: repoKey)
        if !FileManager.default.fileExists(atPath: annoRoot.path(percentEncoded: false)) {
            try! FileManager.default.createDirectory(at: annoRoot, withIntermediateDirectories: true)
        }
    }
    
    func readAsync() async throws -> AnnoDetailStruct {
        if shouldFetchFromNetwork {
            let result = try await fetchAnnouncements()
            storeFetch(date: Date.now)
            return result
        } else {
            if let localResult = readAnnouncements() {
                return localResult
            } else {
                let result = try await fetchAnnouncements()
                storeFetch(date: Date.now)
                return result
            }
        }
    }
    
    // 从官方获取数据
    func fetchAnnouncements() async throws -> AnnoDetailStruct {
        let annoRequest = RequestBuilder.buildRequest(
            method: .GET, host: Endpoints.Hk4eAnnApi,
            path: "/common/hk4e_cn/announcement/api/getAnnContent",
            queryItems: Endpoints.annoQuery
        )
        let annoResult = try await NetworkClient.simpleDataClient(request: annoRequest, type: AnnoDetailStruct.self)
        if annoResult.retcode == 0 {
            try JSONEncoder().encode(annoResult).write(to: annoRoot.appending(path: annoFile))
            return annoResult
        } else {
            throw NSError(
                domain: "AnnouncementPart", code: -10,
                userInfo: [NSLocalizedDescriptionKey: "Cannot fetch announcement detail: \(annoResult.message)"]
            )
        }
    }
    
    // 从本地读取数据
    private func readAnnouncements() -> AnnoDetailStruct? {
        try? JSONDecoder().decode(AnnoDetailStruct.self, from: Data(contentsOf: annoRoot.appending(path: annoFile)))
    }
}

struct AnnoDetailStruct: Codable {
    let retcode: Int
    let message: String
    let data: DetailList
}

extension AnnoDetailStruct {
    struct DetailList: Codable {
        let total: Int
        let list: [AnnoUnit]
    }
}

extension AnnoDetailStruct.DetailList {
    struct AnnoUnit: Codable, Identifiable {
        let id: String = UUID().uuidString
        let annId: Int
        let title: String
        let subtitle: String
        let banner: String
        let content: String
        
        enum CodingKeys: String, CodingKey {
            case annId = "ann_id"
            case title, subtitle, banner, content
        }
    }
}
