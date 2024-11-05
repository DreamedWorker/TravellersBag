//
//  TBErrors.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/26.
//

import Foundation

enum TBErrors: Error, CustomStringConvertible, LocalizedError {
    /// 角色信息未下载
    case avatarDownloadError
    
    var description: String {
        switch self {
        case .avatarDownloadError:
            return NSLocalizedString("error.wizard.resourceAvatarDownload", comment: "")
        }
    }
}
