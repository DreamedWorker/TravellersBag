//
//  DailyNoteDetail.swift
//  DailyNoteWidgetExtension
//
//  Created by 鸳汐 on 2025/1/16.
//

import Foundation

struct NoteContext: Codable {
    var max_resin: Int = -1
    var resin_recovery_time: String = "0"
    var current_resin: Int = 0
    
    var total_task_num: Int = 0
    var finished_task_num: Int = 0
    var is_extra_task_reward_received: Bool = false
    
    var max_home_coin: Int = 0
    var current_home_coin: Int = 0
    
    var max_expedition_num: Int = 0
    var current_expedition_num: Int = 0
    var expeditions: [Expedition] = []
    
    var has_signed: Bool = false
}

extension NoteContext {
    struct Expedition: Codable {
        var avatar_side_icon: String = ""
        var status: String = ""
    }
}
