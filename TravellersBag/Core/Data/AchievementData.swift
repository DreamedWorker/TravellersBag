//
//  AchievementData.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/27.
//

import Foundation

struct AchieveList: Identifiable, Hashable {
    var id: Int
    var order: Int
    var name: String
    var icon: String
}

struct MakeArchive {
    var showIt: Bool
    var name: String
    
    init(showIt: Bool = false, name: String = "") {
        self.showIt = showIt
        self.name = name
    }
    
    mutating func clearAll() {
        showIt = false; name = ""
    }
}

enum AchievePart {
    case Loading
    case Content
    case NoAccount
    case NoResource
}
