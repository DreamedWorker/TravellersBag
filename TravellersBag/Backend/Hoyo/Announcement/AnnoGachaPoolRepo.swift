//
//  AnnoGachaPoolRepo.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/23.
//

import Foundation

class AnnoGachaPoolRepo: AutocheckedKey, @unchecked Sendable {
    private let repoKey = "AnnouncementGachaLastFetch"
    private let annoRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(path: "Anno")
    private let annoFile = "AnnoGachaList.json"
    private let annoQuery: [URLQueryItem] = [.init(name: "app_sn", value: "ys_obc")]
    
    init() {
        super.init(configKey: repoKey, dailyCheckedKey: true)
        if !FileManager.default.fileExists(atPath: annoRoot.path(percentEncoded: false)) {
            try! FileManager.default.createDirectory(at: annoRoot, withIntermediateDirectories: true)
        }
    }
    
    func readAsync() async throws -> GachaPools {
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
    private func readAnnouncements() -> GachaPools? {
        try? JSONDecoder().decode(GachaPools.self, from: Data(contentsOf: annoRoot.appending(path: annoFile)))
    }
    
    // 从官方获取数据
    func fetchAnnouncements() async throws -> GachaPools {
        let annoRequest = RequestBuilder.buildRequest(
            method: .GET, host: Endpoints.ActApiTakumi, path: "/common/blackboard/ys_obc/v1/gacha_pool", queryItems: annoQuery
        )
        let annoResult = try await NetworkClient.simpleDataClient(request: annoRequest, type: GachaPools.self)
        if annoResult.retcode == 0 {
            try JSONEncoder().encode(annoResult).write(to: annoRoot.appending(path: annoFile))
            return annoResult
        } else {
            throw NSError(
                domain: "AnnouncementPart", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Cannot fetch gacha pools: \(annoResult.message)"]
            )
        }
    }
}
