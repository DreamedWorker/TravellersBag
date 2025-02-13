//
//  NoticeError.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/28.
//

import Foundation

enum NoticeError: Error {
    case noticeDecode
    case noticeDetailDecode
    case noticeRequest(String)
    case noticeDetailRequest(String)
}
