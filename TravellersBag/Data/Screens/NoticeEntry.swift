//
//  NoticeEntry.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/9.
//

import Foundation

struct NoticeEntry: Identifiable {
    var id: Int
    var annId: Int
    var title: String
    var subtitle: String
    var banner: String
    var type_label: String
    var type: Int
    var start: String
    var end: String
}
