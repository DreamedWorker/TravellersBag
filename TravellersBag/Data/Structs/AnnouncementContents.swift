//
//  AnnouncementContents.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/2/10.
//


// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let announcementContents = try? JSONDecoder().decode(AnnouncementContents.self, from: jsonData)

import Foundation

// MARK: - AnnouncementContents
struct AnnouncementContents: Codable {
    let total: Int
    let picList: [JSONAny]
    let picTotal: Int
    let list: [DetailList]
    
    // MARK: - List
    struct DetailList: Codable {
        let title: String
        let banner: String
        let annID: Int
        let content: String
        let subtitle: String
        let lang: NoticeLang

        enum CodingKeys: String, CodingKey {
            case title = "title"
            case banner = "banner"
            case annID = "ann_id"
            case content = "content"
            case subtitle = "subtitle"
            case lang = "lang"
        }
    }

    enum NoticeLang: String, Codable {
        case zhCN = "zh-cn"
    }

    enum CodingKeys: String, CodingKey {
        case total = "total"
        case picList = "pic_list"
        case picTotal = "pic_total"
        case list = "list"
    }
}
