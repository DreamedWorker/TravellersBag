//
//  NoticeService.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/28.
//

import Foundation

class NoticeService {
    static let noticeRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "LocalNotice")
    
    private static func write2disk(name: String, data: Data) {
        let file = noticeRoot.appending(component: "\(name).json")
        FileManager.default.createFile(atPath: file.toStringPath(), contents: data)
    }
    
    private static func read4disk(name: String) throws -> Data {
        let file = noticeRoot.appending(component: "\(name).json")
        if FileManager.default.fileExists(atPath: file.toStringPath()) {
            return try Data(contentsOf: file)
        } else {
            return Data()
        }
    }
    
    static func fetchNoticeContent() async -> Result<AnnouncementContents, NoticeError> {
        do {
            let localData = try read4disk(name: "NoticeDetails")
            let structureData = try JSONDecoder().decode(AnnouncementContents.self, from: localData)
            return .success(structureData)
        } catch {
            let req = URLRequest(url: URL(string: ApiEndpoints.shared.getHk4eAnnounceContext())!)
            switch await NetworkTask.fetchFromRemote(request: req) {
            case .success(let data):
                do {
                    write2disk(name: "NoticeDetails", data: data)
                    let structureData = try JSONDecoder().decode(AnnouncementContents.self, from: data)
                    return .success(structureData)
                } catch {
                    return .failure(.noticeDetailDecode)
                }
            case .failure(let fail):
                switch fail {
                case .systemLayer(_):
                    return .failure(.noticeDetailRequest(NSLocalizedString("def.error.systemCFLayer", comment: "")))
                case .requestLayer(let msg):
                    return .failure(.noticeDetailRequest(msg))
                }
            }
        }
    }
    
    static func fetchNoticeList() async -> Result<AnnouncementList, NoticeError> {
        do {
            let localData = try read4disk(name: "NoticeList")
            let structureData = try JSONDecoder().decode(AnnouncementList.self, from: localData)
            return .success(structureData)
        } catch {
            let req = URLRequest(url: URL(string: ApiEndpoints.shared.getHk4eAnnouncement())!)
            switch await NetworkTask.fetchFromRemote(request: req) {
            case .success(let data):
                do {
                    write2disk(name: "NoticeList", data: data)
                    let structureData = try JSONDecoder().decode(AnnouncementList.self, from: data)
                    return .success(structureData)
                } catch {
                    return .failure(.noticeDecode)
                }
            case .failure(let fail):
                switch fail {
                case .systemLayer(_):
                    return .failure(.noticeRequest(NSLocalizedString("def.error.systemCFLayer", comment: "")))
                case .requestLayer(let content):
                    return .failure(.noticeRequest(content))
                }
            }
        }
    }
}
