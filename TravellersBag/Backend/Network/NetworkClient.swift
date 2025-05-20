//
//  NetworkClient.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/15.
//

import Foundation

class NetworkClient {
    static func simpleDataClient<T: Decodable>(request: URLRequest, type: T.Type) async throws -> T {
        let (result, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(type, from: result)
    }
    
    static func simpleDownloadClient(request: URLRequest, targetFile: URL) async throws {
        if FileManager.default.fileExists(atPath: targetFile.path(percentEncoded: false)) {
            try! FileManager.default.removeItem(at: targetFile)
        } else {
            let parent = targetFile.deletingLastPathComponent()
            try! FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        }
        let (tempURL, _) = try await URLSession.shared.download(for: request)
        try FileManager.default.moveItem(at: tempURL, to: targetFile)
    }
}
