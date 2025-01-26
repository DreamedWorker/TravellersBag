//
//  DownloadManager.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/25.
//

import Foundation

class DownloadManager: NSObject, URLSessionDownloadDelegate {
    
    private lazy var urlSession = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
    private var downloadTask: URLSessionDownloadTask? = nil
    
    /// 完全在主线程执行
    private let progressEvt: (Float) -> Void
    /// 需要配置主线程执行
    private let finishedEvt: (URL) -> Void
    
    init(progressEvt: @escaping (Float) -> Void, finishedEvt: @escaping (URL) -> Void) {
        self.progressEvt = progressEvt
        self.finishedEvt = finishedEvt
    }
    
    func startDownload(fileUrl url: String) {
        downloadTask = urlSession.downloadTask(with: URLRequest(url: URL(string: url)!))
        downloadTask?.resume() // 启动任务
    }
    
    func urlSession(
        _ session: URLSession, downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64
    ) {
        DispatchQueue.main.async {
            let calculatedProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            self.progressEvt(calculatedProgress)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        finishedEvt(location)
    }
}
