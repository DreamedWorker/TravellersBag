//
//  URLSessions.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/25.
//

import Foundation

/// 返回一个默认的会话
func httpSession() -> URLSession {
    return URLSession.shared // 由于无需考虑用户是否使用代理（不走代理），故仅用默认的即可。
}

extension URLSession {
    /// 下载文件，你提供的url必须是位于沙盘中的路径
    func download2File(url: URL, req: URLRequest) async throws {
        let data = try await self.download(for: req)
        if FileManager.default.fileExists(atPath: url.path().removingPercentEncoding!) {
            // 存在旧文件的话就删除，不然下面的moveItem方法会报错。
            try! FileManager.default.removeItem(at: url)
        }
        try FileManager.default.moveItem(at: data.0, to: url)
    }
    
    /// 下载文件任务，你提供的url必须是位于沙盘中的路径（用于监听进度）
    func buildDownloadTask(url: URL, req: URLRequest) -> URLSessionDownloadTask {
        let downloadTask = self.downloadTask(with: req, completionHandler: { (tempUrl, response, errors) in
            if errors != nil { return }
            if let content = tempUrl {
                if FileManager.default.fileExists(atPath: url.path().removingPercentEncoding!) {
                    try! FileManager.default.removeItem(at: url)
                }
                try! FileManager.default.moveItem(at: content, to: url)
            }
        })
        return downloadTask
    }
}
