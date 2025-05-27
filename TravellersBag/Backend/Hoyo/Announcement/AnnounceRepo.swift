//
//  AnnounceRepo.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/20.
//

import Foundation

class AnnounceRepo: AutocheckedKey, @unchecked Sendable {
    private let repoKey = "AnnouncementLastFetch"
    private let annoRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(path: "Anno")
    private let annoFile = "AnnoList.json"
    private let annoQuery: [URLQueryItem] = [
        .init(name: "game", value: "hk4e"), .init(name: "game_biz", value: "hk4e_cn"), .init(name: "lang", value: "zh-cn"),
        .init(name: "bundle_id", value: "hk4e_cn"), .init(name: "platform", value: "pc"), .init(name: "region", value: "cn_gf01"),
        .init(name: "level", value: "55"), .init(name: "uid", value: "100000000")
    ]
    
    init() {
        super.init(configKey: repoKey, dailyCheckedKey: true)
        if !FileManager.default.fileExists(atPath: annoRoot.path(percentEncoded: false)) {
            try! FileManager.default.createDirectory(at: annoRoot, withIntermediateDirectories: true)
        }
    }
    
    // 先判断是否需要从官方获取数据 如果从本地获取数据失败（为空的）则从官方获取
    // 从官方获取的都会更新获取时间 只有从官方获取的过程会抛出错误
    func readAsync() async throws -> AnnoStruct {
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
    
    // 从本地读取数据
    private func readAnnouncements() -> AnnoStruct? {
        try? JSONDecoder().decode(AnnoStruct.self, from: Data(contentsOf: annoRoot.appending(path: annoFile)))
    }
    
    // 从官方获取数据
    func fetchAnnouncements() async throws -> AnnoStruct {
        let annoRequest = RequestBuilder.buildRequest(
            method: .GET, host: Endpoints.Hk4eAnnApi, path: "/common/hk4e_cn/announcement/api/getAnnList", queryItems: annoQuery
        )
        let annoResult = try await NetworkClient.simpleDataClient(request: annoRequest, type: AnnoStruct.self)
        if annoResult.retcode == 0 {
            try JSONEncoder().encode(annoResult).write(to: annoRoot.appending(path: annoFile))
            return annoResult
        } else {
            throw NSError(
                domain: "AnnouncementPart", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Cannot fetch announcements: \(annoResult.message)"]
            )
        }
    }
}
