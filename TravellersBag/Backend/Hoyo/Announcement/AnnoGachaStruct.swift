//
//  AnnoGachaStruct.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/20.
//

import Foundation

extension AnnoGachaPoolRepo {
    struct GachaPools: Codable {
        let retcode: Int
        let message: String
        let data: GachaPoolData
    }
}

extension AnnoGachaPoolRepo.GachaPools {
    struct GachaPoolData: Codable {
        let list: [PoolList]
    }
    
    struct PoolList: Codable {
        let id: Int
        let title: String
        let activityURL: String
        let contentBeforeAct: String
        let pool: [Pool]
        let voiceIcon, voiceURL: String
        let voiceStatus: Int
        let startTime, endTime: String

        enum CodingKeys: String, CodingKey {
            case id, title
            case activityURL = "activity_url"
            case contentBeforeAct = "content_before_act"
            case pool
            case voiceIcon = "voice_icon"
            case voiceURL = "voice_url"
            case voiceStatus = "voice_status"
            case startTime = "start_time"
            case endTime = "end_time"
        }
    }
    
    struct Pool: Codable {
        let icon: String
        let url: String
        let ext: String
    }
}
