//
//  DailyNoteData.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/30.
//

import Foundation

struct ArchonTask: Identifiable {
    var id: Int
    var chapter_title: String
    var chapter_num: String
    var status: String
    var chapter_type: Int
}

struct ExpeditionTask: Identifiable {
    var avatar_side_icon: String
    var status: String
    var remained_time: String
    var id: String
}
