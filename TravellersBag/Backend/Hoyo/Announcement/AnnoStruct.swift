//
//  AnnoStruct.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/20.
//

import Foundation

extension AnnounceRepo {
    struct AnnoStruct: Codable {
        let retcode: Int
        let message: String
        let data: AnnoData
    }
}

extension AnnounceRepo.AnnoStruct {
    struct AnnoData: Codable {
        let list: [DataList]
        let total: Int
        let typeList: [TypeList]
        let alert: Bool
        let alertID, timezone: Int
        let t: String
        let picTotal: Int
        let picAlert: Bool
        let picAlertID: Int
        let staticSign, banner: String
        let calendarType: CalendarType

        enum CodingKeys: String, CodingKey {
            case list, total
            case typeList = "type_list"
            case alert
            case alertID = "alert_id"
            case timezone, t
            case picTotal = "pic_total"
            case picAlert = "pic_alert"
            case picAlertID = "pic_alert_id"
            case staticSign = "static_sign"
            case banner
            case calendarType = "calendar_type"
        }
    }
    
    struct CalendarType: Codable {
        let mi18NName: String
        let enabled, remind: Bool

        enum CodingKeys: String, CodingKey {
            case mi18NName = "mi18n_name"
            case enabled, remind
        }
    }
    
    struct DataList: Codable {
        let list: [AnnoList]
        let typeID: Int
        let typeLabel: TypeLabel

        enum CodingKeys: String, CodingKey {
            case list
            case typeID = "type_id"
            case typeLabel = "type_label"
        }
    }
    
    struct AnnoList: Codable {
        let annID: Int
        let title, subtitle: String
        let banner: String
        let content: String
        let typeLabel: TypeLabel
        let tagLabel: TagLabel
        let tagIcon: String
        let loginAlert: Int
        let startTime, endTime: String
        let type, remind, alert: Int
        let remindVer: Int
        let hasContent: Bool
        let extraRemind: Int
        let tagIconHover: String
        let logoutRemind, logoutRemindVer: Int
        let country: String
        let needRemindText: Int
        let remindText: String
        let weakRemind, remindConsumptionType: Int

        enum CodingKeys: String, CodingKey {
            case annID = "ann_id"
            case title, subtitle, banner, content
            case typeLabel = "type_label"
            case tagLabel = "tag_label"
            case tagIcon = "tag_icon"
            case loginAlert = "login_alert"
            case startTime = "start_time"
            case endTime = "end_time"
            case type, remind, alert
            case remindVer = "remind_ver"
            case hasContent = "has_content"
            case extraRemind = "extra_remind"
            case tagIconHover = "tag_icon_hover"
            case logoutRemind = "logout_remind"
            case logoutRemindVer = "logout_remind_ver"
            case country
            case needRemindText = "need_remind_text"
            case remindText = "remind_text"
            case weakRemind = "weak_remind"
            case remindConsumptionType = "remind_consumption_type"
        }
    }
    
    enum TagLabel: String, Codable {
        case 扭蛋 = "扭蛋"
        case 活动 = "活动"
        case 重要 = "重要"
    }
    
    enum TypeLabel: String, Codable {
        case 活动公告 = "活动公告"
        case 游戏公告 = "游戏公告"
    }
    
    struct TypeList: Codable {
        let id: Int
        let name: String
        let mi18NName: TypeLabel

        enum CodingKeys: String, CodingKey {
            case id, name
            case mi18NName = "mi18n_name"
        }
    }
}
