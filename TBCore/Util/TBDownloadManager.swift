//
//  TBDownloadManager.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/25.
//

import Foundation

/// 自定义的下载代理
class TBDownloadManager : NSObject, URLSessionDownloadDelegate {
    private lazy var urlSession: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    private var downloadTask: URLSessionDownloadTask? = nil
    
    private let postDownload: (URL) -> Void
    private let onDownload: (Float) -> Void
    
    init(downloadTask: URLSessionDownloadTask? = nil, postDownload: @escaping (URL) -> Void, onDownload: @escaping (Float) -> Void) {
        self.downloadTask = downloadTask
        self.postDownload = postDownload
        self.onDownload = onDownload
    }
    
    /// 开启下载任务 传入链接
    func startDownload(url: String, beforeDownload: () -> Void) {
        beforeDownload()
        downloadTask = urlSession.downloadTask(with: URLRequest(url: URL(string: url)!))
        downloadTask?.resume()
    }
    
    /// 取消任务
    func cancelDownload(relative: (() -> Void)?) {
        if let task = relative { task() }
        downloadTask?.cancel()
    }
    
    func urlSession(
        _ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            onDownload(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))
        }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        postDownload(location)
    }
}
