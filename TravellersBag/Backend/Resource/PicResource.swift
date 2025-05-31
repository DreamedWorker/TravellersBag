//
//  PicResource.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/31.
//

import Foundation
import Zip

class PicResource {
    static let imageRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "resource").appending(component: "imgs")
    static let imagesDownloadList: [String] =
    ["AvatarIcon", "AvatarIconCircle", "AchievementIcon", "Bg", "ChapterIcon", "EquipIcon",
     "NameCardIcon", "NameCardPic", "Property", "RelicIcon", "Skill", "Talent"]
    
    static func checkWhenLaunching() {
        if !FileManager.default.fileExists(atPath: imageRoot.path(percentEncoded: false)) {
            try! FileManager.default.createDirectory(at: imageRoot, withIntermediateDirectories: true)
        }
    }
    
    static func hasLocalImgs() -> Bool {
        let lastOne = imagesDownloadList.last!
        return FileManager.default.fileExists(atPath: imageRoot.appending(component: lastOne).path(percentEncoded: false))
    }
}

extension PicResource {
    class SequentialDownloader: NSObject, @unchecked Sendable, URLSessionDownloadDelegate {
        private var currentDownloadTask: URLSessionDownloadTask? = nil
        private var progressHandler: ((URL, Double) -> Void)?
        private var completionHandler: ((Result<[URL: URL], Error>) -> Void)?
        private lazy var urlSession: URLSession = {
            let configuration = URLSessionConfiguration.ephemeral
            return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        }()
        
        private var fileURLs: [URL] = []
        private var currentIndex = 0
        private var isPaused = false
        private var resumeData: Data?
        private var downloadedFiles: [URL: URL] = [:]  // [原始URL: 本地临时文件URL]
        private var observations = [NSKeyValueObservation]()
        
        func pause() {
            guard let task = currentDownloadTask else { return }
            isPaused = true
            task.cancel { [weak self] resumeData in
                self?.resumeData = resumeData
            }
        }
        
        func resume() {
            guard isPaused else { return }
            isPaused = false
            if let resumeData = resumeData {
                // 恢复已暂停的下载
                let task = urlSession.downloadTask(withResumeData: resumeData)
                setupTaskObservers(task: task)
                task.resume()
                currentDownloadTask = task
            } else {
                // 如果没有恢复数据，重新开始当前下载
                downloadNext()
            }
        }
        
        func cancel() {
            currentDownloadTask?.cancel()
            currentDownloadTask = nil
            observations.removeAll()
            isPaused = false
            resumeData = nil
        }
        
        deinit {
            cancel()
        }
        
        // 图像资源更新无法预测 故没有差异化下载的必要
        func startDownload(
            urls: [URL],
            progressHandler: @escaping (URL, Double) -> Void,
            completion: @escaping (Result<[URL: URL], Error>) -> Void
        ) {
            self.fileURLs = urls
            self.progressHandler = progressHandler
            self.completionHandler = completion
            self.downloadedFiles = [:]
            self.currentIndex = 0
            self.isPaused = false
            downloadNext()
        }
        
        private func downloadNext() {
            guard currentIndex < fileURLs.count else {
                completionHandler?(.success(downloadedFiles))
                return
            }
            let currentURL = fileURLs[currentIndex]
            if isPaused {
                return
            }
            if let resumeData = resumeData {
                // 恢复已暂停的下载
                let task = urlSession.downloadTask(withResumeData: resumeData)
                self.resumeData = nil
                setupTaskObservers(task: task)
                task.resume()
                currentDownloadTask = task
            } else {
                // 开始新的下载
                let task = urlSession.downloadTask(with: currentURL)
                setupTaskObservers(task: task)
                task.resume()
                currentDownloadTask = task
            }
        }
        
        private func setupTaskObservers(task: URLSessionDownloadTask) {
            // 移除之前的观察者
            observations.removeAll()
            // 进度观察
            let progressObservation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
                guard let self = self, let currentURL = self.currentIndex < self.fileURLs.count ? self.fileURLs[self.currentIndex] : nil else {
                    return
                }
                self.progressHandler?(currentURL, progress.fractionCompleted)
            }
            observations.append(progressObservation)
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
            guard currentIndex < fileURLs.count else { return }
            let currentURL = fileURLs[currentIndex]
            let unzippedFolder = PicResource.imageRoot.appending(component: String(currentURL.lastPathComponent.split(separator: ".")[0]))
            // 将文件移动到永久位置
            let fileManager = FileManager.default
            let destinationURL = PicResource.imageRoot.appending(component: currentURL.lastPathComponent)
            do {
                if fileManager.fileExists(atPath: unzippedFolder.path(percentEncoded: false)) {
                    try fileManager.removeItem(at: unzippedFolder)
                }
                try fileManager.createDirectory(at: unzippedFolder, withIntermediateDirectories: true)
                try? fileManager.removeItem(at: destinationURL)  // 删除已存在的文件
                try fileManager.moveItem(at: location, to: destinationURL)
                try Zip.unzipFile(destinationURL, destination: unzippedFolder, overwrite: true, password: nil)
                downloadedFiles[currentURL] = destinationURL
                currentIndex += 1
                try fileManager.removeItem(at: destinationURL)
                downloadNext()
            } catch {
                completionHandler?(.failure(error))
                cancel()
            }
        }
    }
}
