//
//  AnnoHotActStruct.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/27.
//

import Foundation

struct AnnoHotActStruct: Codable {
    let retcode: Int
    let message: String
    let data: ActivityList
}

extension AnnoHotActStruct {
    struct ActivityList: Codable {
        let list: [ChildElement]
    }
}

extension AnnoHotActStruct.ActivityList {
    struct ChildElement: Codable {
        let id: Int
        let name: String
        let parentID, depth: Int
        let chEXT: String
        let children: [ChildElement]
        let list: [PurpleList]
        let isRecentUpdate: Bool

        enum CodingKeys: String, CodingKey {
            case id, name
            case parentID = "parent_id"
            case depth
            case chEXT = "ch_ext"
            case children, list
            case isRecentUpdate = "is_recent_update"
        }
    }
}

extension AnnoHotActStruct.ActivityList.ChildElement {
    struct PurpleList: Codable {
        let recommendID, contentID: Int
        let title, ext: String
        let type: Int
        let url: String
        let icon: String
        let abstract, articleUserName, avatarURL, articleTime: String
        let createTime, endTime, cornerMark: String

        enum CodingKeys: String, CodingKey {
            case recommendID = "recommend_id"
            case contentID = "content_id"
            case title, ext, type, url, icon, abstract
            case articleUserName = "article_user_name"
            case avatarURL = "avatar_url"
            case articleTime = "article_time"
            case createTime = "create_time"
            case endTime = "end_time"
            case cornerMark = "corner_mark"
        }
    }
}
