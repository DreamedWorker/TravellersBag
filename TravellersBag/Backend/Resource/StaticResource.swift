//
//  StaticResource.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/15.
//

import Foundation
import SwiftyJSON

class StaticResource {
    typealias StaticMeta = [String:String]
    private static let remotePath = "/Genshin/CHS/"
    private static let resourceRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(path: "resource").appending(path: "jsons")
    
    static func checkExistWhenLaunching() {
        if FileManager.default.fileExists(atPath: resourceRoot.path(percentEncoded: false)) {
            try! FileManager.default.createDirectory(at: resourceRoot, withIntermediateDirectories: true)
        }
    }
}

// MARK: - 资源下载
extension StaticResource {
    static func downloadStaticResource(progressReporter: @escaping @Sendable (Int, Int) async -> Void) async throws {
        let localMeta = readLocalMetaList()
        let remoteMeta = try await fetchRemoteMetaList()
        let total = remoteMeta.count
        await progressReporter(0, total)
        for (index, file) in remoteMeta.enumerated() {
            if let localMeta = localMeta {
                if localMeta.keys.contains(file.key) {
                    let localXXHash = localMeta[file.key]!
                    if localXXHash == file.value { // 本地与云端无异
                        if FileManager.default.fileExists(
                            atPath: LocalPath.getPath(prefix: resourceRoot, relative: file.key + ".json").path(percentEncoded: false)
                        ) { // 本地存在文件
                            await progressReporter(index + 1, total)
                            continue
                        }
                    }
                }
            }
            let fileRequest = RequestBuilder.buildRequest(
                method: .GET, host: Endpoints.HutaoMetadataApi, path: remotePath + file.key + ".json", queryItems: []
            )
            let targetFile = LocalPath.getPath(prefix: resourceRoot, relative: file.key + ".json")
            try await NetworkClient.simpleDownloadClient(request: fileRequest, targetFile: targetFile)
            await progressReporter(index + 1, total)
        }
        // 将新的meta.json写入本地
        try JSONEncoder().encode(remoteMeta).write(to: resourceRoot.appending(path: "meta.json"))
        try createAvatarList(avatarPath: resourceRoot.appending(path: "Avatar"))
    }
    
    private static func createAvatarList(avatarPath: URL) throws {
        var avatars: [JSON] = []
        try FileManager.default.contentsOfDirectory(atPath: avatarPath.path(percentEncoded: false)).forEach { filename in
            avatars.append(try JSON(parseJSON: String(contentsOf: avatarPath.appending(path: filename), encoding: .utf8)))
        }
        let parentPath = avatarPath.deletingLastPathComponent()
        avatars = avatars.sorted(by: { $0["Id"].intValue < $1["Id"].intValue })
        try avatars.description.data(using: .utf8)!.write(to: parentPath.appending(path: "Avatar.json"))
    }
    
    private static func readLocalMetaList() -> StaticMeta? {
        let metaFile = resourceRoot.appending(path: "meta.json")
        if !FileManager.default.fileExists(atPath: metaFile.path(percentEncoded: false)) {
            return nil
        }
        return try? JSONDecoder().decode(StaticMeta.self, from: Data(contentsOf: metaFile))
    }
    
    private static func fetchRemoteMetaList() async throws -> StaticMeta {
        let request = RequestBuilder.buildRequest(method: .GET, host: Endpoints.HutaoMetadataApi, path: remotePath + "Meta.json", queryItems: [])
        return try await NetworkClient.simpleDataClient(request: request, type: StaticMeta.self)
    }
}
